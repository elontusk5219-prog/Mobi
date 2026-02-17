//
//  AmbientSoundService.swift
//  Mobi
//
//  Genesis（Amina）阶段背景氛围乐；AVAudioEngine DSP 随 MobiMood 变化。
//  不修改 AVAudioSession，沿用应用全局 .playAndRecord，避免与 Doubao 实时语音（麦克风+TTS）冲突。
//

import Foundation
import AVFoundation

/// 最大保留约 0.5 秒 48k 单声道
private let kPlaybackRingCapacity = 24_000

final class AmbientSoundService: PlaybackReferenceProvider {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private let eq = AVAudioUnitEQ(numberOfBands: 3)
    private let queue = DispatchQueue(label: "com.mobi.ambient.audio")
    private var buffer: AVAudioPCMBuffer?
    private var bufferFormat: AVAudioFormat?
    private var fadeWorkItem: DispatchWorkItem?
    private var isPlaying = false
    private var playbackRing = [Float](repeating: 0, count: kPlaybackRingCapacity)
    private var playbackRingHead = 0
    private let ringLock = NSLock()
    private var playbackTapInstalled = false
    /// Turn 11–15: high-frequency ping (2–4 kHz)；氛围音量微降以贴近「reverb 递减 / 渐入视频」听感（P3-1）。
    private var pingNode: AVAudioPlayerNode?
    private var pingBuffer: AVAudioPCMBuffer?
    private var pingFormat: AVAudioFormat?
    private var pingInterval: TimeInterval = 2.0
    private var pingWorkItem: DispatchWorkItem?
    private var genesisLateTurn: Int = 0
    /// Turn 11→15 时主 ambient 音量乘数（1.0 → 约 0.8），与 ping 一起实现「渐入视频」。
    private var latePhaseVolumeScale: Float = 1.0

    init() {
        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.attach(eq)
        let mainMixer = engine.mainMixerNode
        engine.connect(playerNode, to: timePitch, format: nil)
        engine.connect(timePitch, to: eq, format: nil)
        engine.connect(eq, to: mainMixer, format: nil)
        applyMood(.neutral)
    }

    /// Load GenesisAmbient.mp3, buffer, and schedule infinite loop. Call before fadeIn.
    func playGenesisLoop() {
        queue.async { [weak self] in
            self?._playGenesisLoop()
        }
    }

    private func _playGenesisLoop() {
        let url = Bundle.main.url(forResource: "GenesisAmbient", withExtension: "mp3", subdirectory: "Resources/Audio")
            ?? Bundle.main.url(forResource: "GenesisAmbient", withExtension: "MP3", subdirectory: "Resources/Audio")
            ?? Bundle.main.url(forResource: "GenesisAmbient", withExtension: "mp3")
            ?? Bundle.main.url(forResource: "GenesisAmbient", withExtension: "MP3")
        guard let url = url else {
            print("[AmbientSound] GenesisAmbient.mp3 not found. Put it in Mobi/Resources/Audio/ or bundle root.")
            return
        }
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let frameCount = UInt32(file.length)
            guard frameCount > 0,
                  let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("[AmbientSound] Failed to create buffer")
                return
            }
            try file.read(into: buf)
            buffer = buf
            bufferFormat = format

            engine.connect(playerNode, to: timePitch, format: format)
            if engine.isRunning == false { try? engine.start() }
            scheduleLoop()
            playerNode.volume = 0
            playerNode.play()
            isPlaying = true
            installPlaybackTap(format: format)
        } catch {
            print("[AmbientSound] Load failed: \(error)")
        }
    }

    private func scheduleLoop() {
        guard let buf = buffer, bufferFormat != nil else { return }
        playerNode.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
    }

    private func installPlaybackTap(format: AVAudioFormat) {
        guard !playbackTapInstalled, format.channelCount > 0 else { return }
        let bufferSize: AVAudioFrameCount = 1024
        playerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buf, _ in
            self?.pushPlaybackToRing(buf)
        }
        playbackTapInstalled = true
    }

    private func pushPlaybackToRing(_ pcm: AVAudioPCMBuffer) {
        guard let ch0 = pcm.floatChannelData?[0] else { return }
        let frameLength = Int(pcm.frameLength)
        let channelCount = Int(pcm.format.channelCount)
        guard channelCount > 0 else { return }
        let ch1 = channelCount > 1 ? pcm.floatChannelData?[1] : nil
        ringLock.lock()
        for i in 0..<frameLength {
            let sample: Float
            if let c1 = ch1 {
                sample = (ch0[i] + c1[i]) * 0.5
            } else {
                sample = ch0[i]
            }
            playbackRing[playbackRingHead % kPlaybackRingCapacity] = sample
            playbackRingHead += 1
        }
        ringLock.unlock()
    }

    func getPlaybackReference(frameCount: Int) -> [Float]? {
        ringLock.lock()
        defer { ringLock.unlock() }
        guard playbackRingHead >= frameCount else { return nil }
        var out = [Float](repeating: 0, count: frameCount)
        let start = (playbackRingHead - frameCount + kPlaybackRingCapacity) % kPlaybackRingCapacity
        for i in 0..<frameCount {
            out[i] = playbackRing[(start + i) % kPlaybackRingCapacity]
        }
        return out
    }

    func updateMood(_ mood: MobiMood) {
        queue.async { [weak self] in
            self?.applyMood(mood)
        }
    }

    /// Sensory Progression: low shelf +3dB as progress 0→1 (distance to intimacy, warmth).
    func updateSensoryProgress(_ progress: Float) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let p = min(1, max(0, progress))
            let band = self.eq.bands[2]
            band.filterType = .lowShelf
            band.frequency = 200
            band.bandwidth = 1
            band.gain = 3 * p
            band.bypass = p < 0.01
        }
    }

    /// Turn 11–15: start periodic 2–4 kHz ping (speed increases with turn)；主 ambient 音量微降（reverb 递减 / 渐入视频，P3-1）。
    func updateGenesisLatePhase(turn: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.genesisLateTurn = turn
            let oldScale = self.latePhaseVolumeScale
            if turn >= 11 {
                self.pingInterval = max(0.5, 2.0 - Double(turn - 11) * 0.28)
                self.startPingIfNeeded(turn: turn)
                self.latePhaseVolumeScale = Float(max(0.8, 1.0 - Double(turn - 11) * 0.05))
            } else {
                self.latePhaseVolumeScale = 1.0
            }
            if self.isPlaying, oldScale > 0 {
                self.playerNode.volume = self.playerNode.volume / oldScale * self.latePhaseVolumeScale
            }
        }
    }

    private func startPingIfNeeded(turn: Int) {
        guard pingNode == nil, let format = bufferFormat ?? AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1) else { return }
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        if engine.isRunning == false { try? engine.start() }
        pingNode = node
        pingFormat = format
        pingBuffer = makePingBuffer(format: format)
        pingInterval = max(0.5, 2.0 - Double(turn - 11) * 0.28)
        schedulePingLoop()
    }

    private func makePingBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * 0.05)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        guard let ch = buf.floatChannelData?[0] else { return nil }
        let freq: Float = 3000
        for i in 0..<Int(frameCount) {
            ch[i] = 0.15 * sin(2 * .pi * freq * Float(i) / Float(sampleRate))
        }
        return buf
    }

    private func schedulePingLoop() {
        pingWorkItem?.cancel()
        guard let node = pingNode, let buf = pingBuffer else { return }
        node.scheduleBuffer(buf, at: nil, options: []) { [weak self] in
            guard let self = self else { return }
            let item = DispatchWorkItem { [weak self] in
                self?.schedulePingLoop()
            }
            self.pingWorkItem = item
            self.queue.asyncAfter(deadline: .now() + self.pingInterval, execute: item)
        }
        if node.isPlaying == false { node.play() }
    }

    func stopGenesisPing() {
        queue.async { [weak self] in
            self?.pingWorkItem?.cancel()
            self?.pingNode?.stop()
            if let n = self?.pingNode { self?.engine.detach(n) }
            self?.pingNode = nil
            self?.genesisLateTurn = 0
            self?.latePhaseVolumeScale = 1.0
        }
    }

    private func applyMood(_ mood: MobiMood) {
        switch mood {
        case .neutral:
            timePitch.pitch = 0
            timePitch.rate = 1.0
            setEQBypass(true)
        case .happy:
            timePitch.pitch = 200
            timePitch.rate = 1.1
            setEQBypass(true)
        case .sad, .anxious:
            timePitch.pitch = -300
            timePitch.rate = 0.85
            setLowPass(cutoff: 800)
        case .thinking:
            timePitch.pitch = 0
            timePitch.rate = 1.0
            setBandPass(low: 400, high: 2000)
        }
    }

    private func setEQBypass(_ bypass: Bool) {
        let gain: Float = bypass ? 0 : -96
        for i in 0..<eq.bands.count {
            eq.bands[i].filterType = .parametric
            eq.bands[i].frequency = 1000
            eq.bands[i].bandwidth = 1
            eq.bands[i].gain = bypass ? 0 : gain
            eq.bands[i].bypass = bypass
        }
    }

    private func setLowPass(cutoff: Float) {
        eq.bands[0].filterType = .lowPass
        eq.bands[0].frequency = cutoff
        eq.bands[0].bandwidth = 1
        eq.bands[0].gain = 0
        eq.bands[0].bypass = false
        for i in 1..<eq.bands.count {
            eq.bands[i].filterType = .parametric
            eq.bands[i].frequency = 1000
            eq.bands[i].gain = -96
            eq.bands[i].bypass = false
        }
    }

    private func setBandPass(low: Float, high: Float) {
        eq.bands[0].filterType = .highPass
        eq.bands[0].frequency = low
        eq.bands[0].bandwidth = 1
        eq.bands[0].gain = 0
        eq.bands[0].bypass = false
        eq.bands[1].filterType = .lowPass
        eq.bands[1].frequency = high
        eq.bands[1].bandwidth = 1
        eq.bands[1].gain = 0
        eq.bands[1].bypass = false
        eq.bands[2].filterType = .parametric
        eq.bands[2].frequency = 1000
        eq.bands[2].gain = 0
        eq.bands[2].bypass = true
    }

    /// Base max volume to avoid triggering VAD / false interruptions. Use duckVolume for state-based levels.
    private static let baseMaxVolume: Float = 0.15

    func fadeIn(duration: TimeInterval) {
        queue.async { [weak self] in
            self?.fadeWorkItem?.cancel()
            guard let self = self, self.isPlaying else { return }
            let steps = 30
            let stepDuration = duration / Double(steps)
            let stepVolume = Self.baseMaxVolume / Float(steps)
            var step = 0
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, let item = self.fadeWorkItem, !item.isCancelled else { return }
                step += 1
                if step <= steps {
                    self.playerNode.volume = min(Self.baseMaxVolume, stepVolume * Float(step)) * self.latePhaseVolumeScale
                    self.queue.asyncAfter(deadline: .now() + stepDuration, execute: item)
                } else {
                    self.playerNode.volume = Self.baseMaxVolume * self.latePhaseVolumeScale
                }
            }
            self.fadeWorkItem = work
            self.queue.asyncAfter(deadline: .now() + stepDuration, execute: work)
        }
    }

    /// Duck ambient to a target level (e.g. 0.02 when listening to avoid VAD, 0.15 when idle/speaking).
    func duckVolume(to level: Float, duration: TimeInterval = 0.5) {
        queue.async { [weak self] in
            self?.fadeWorkItem?.cancel()
            guard let self = self else { return }
            let steps = max(1, Int(duration / 0.05))
            let stepDuration = duration / Double(steps)
            let startVolume = self.playerNode.volume
            let stepDelta = (level - startVolume) / Float(steps)
            var step = 0
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, let item = self.fadeWorkItem, !item.isCancelled else { return }
                step += 1
                if step <= steps {
                    self.playerNode.volume = max(0, min(1, startVolume + stepDelta * Float(step))) * self.latePhaseVolumeScale
                    self.queue.asyncAfter(deadline: .now() + stepDuration, execute: item)
                } else {
                    self.playerNode.volume = max(0, min(1, level)) * self.latePhaseVolumeScale
                }
            }
            self.fadeWorkItem = work
            self.queue.asyncAfter(deadline: .now() + stepDuration, execute: work)
        }
    }

    func fadeOut(duration: TimeInterval) {
        queue.async { [weak self] in
            self?.fadeWorkItem?.cancel()
            guard let self = self else { return }
            let steps = 30
            let stepDuration = duration / Double(steps)
            let startVolume = self.playerNode.volume
            let stepDelta = startVolume / Float(steps)
            var step = 0
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, let item = self.fadeWorkItem, !item.isCancelled else { return }
                step += 1
                if step <= steps {
                    self.playerNode.volume = max(0, startVolume - stepDelta * Float(step))
                    self.queue.asyncAfter(deadline: .now() + stepDuration, execute: item)
                } else {
                    self.playerNode.volume = 0
                    self.playerNode.stop()
                    self.isPlaying = false
                    self.stopGenesisPing()
                }
            }
            self.fadeWorkItem = work
            self.queue.asyncAfter(deadline: .now() + stepDuration, execute: work)
        }
    }
}
