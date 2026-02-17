//
//  AudioPlayerService.swift
//  Mobi
//
//  TTS 播放：24kHz 单声道 PCM (s16le)，AVAudioEngine + AVAudioPlayerNode。
//  环境声由 AmbientSoundService 负责；本处保留 ambientPlayer 用于 ducking 兼容（若未启动则 no-op）。
//

import Foundation
import AVFoundation
import Combine

final class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()

    /// TTS 输出电平 0...1，用于 Core Flutter 随语音变化
    @Published private(set) var outputLevel: Float = 0

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private let queue = DispatchQueue(label: "com.mobi.audio.player")

    private var ambientPlayer: AVAudioPlayer?
    private var ambientFadeWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    /// 已排队未播完的 TTS buffer 数；播完时若为 0 则触发 onPlaybackQueueDrain（用于「播完再开麦」）
    private var scheduledBufferCount = 0
    /// 当前队列中未播完的音频总时长（秒），用于 no_content 时估算「再等多久开麦」
    private var totalScheduledDuration: TimeInterval = 0
    private var onPlaybackQueueDrain: (() -> Void)?
    /// 首包 TTS 真正入队时调用一次（避免在 count 仍为 0 时注册导致立刻开麦）；调用后置 nil
    var onFirstBufferScheduled: (() -> Void)?
    private let drainLock = NSLock()

    init() {
        self.format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        setupOutputLevelTap()
        do {
            try engine.start()
        } catch {
            print("[AudioPlayer] Engine start failed: \(error)")
        }
        setupDuckingLogic()
    }

    /// Tap playerNode 输出，计算 RMS 供 Core Flutter 随 TTS 变化
    private func setupOutputLevelTap() {
        playerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.int16ChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                let s = Float(channelData[i]) / 32768.0
                sum += s * s
            }
            let rms = frameLength > 0 ? sqrt(sum / Float(frameLength)) : 0
            let level = min(1.0, rms * 4)
            DispatchQueue.main.async { [weak self] in
                self?.outputLevel = level
            }
        }
    }

    private func setupDuckingLogic() {
        MobiEngine.shared.$activityState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    /// 豆包说话/听用户时背景压到很小避免触发 VAD；空闲/思考时恢复至 0.15（不再用 0.3 避免误断）
    private func handleStateChange(_ state: ActivityState) {
        let targetVolume: Float
        let fadeDuration: TimeInterval
        switch state {
        case .speaking:
            targetVolume = 0.02
            fadeDuration = 0.35
        case .listening:
            targetVolume = 0.02   // 几乎静音，避免环境声触发 VAD
            fadeDuration = 0.5
        case .idle, .seeking, .thinking:
            targetVolume = 0.15  // 恢复背景但不吵
            fadeDuration = 1.0
        default:
            targetVolume = 0.15
            fadeDuration = 1.0
        }
        setAmbientVolume(targetVolume, fadeDuration: fadeDuration)
    }

    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {
        queue.async { [weak self] in
            self?._setAmbientVolume(volume, fadeDuration: fadeDuration)
        }
    }

    private func setAmbientVolume(_ volume: Float, fadeDuration: TimeInterval) {
        queue.async { [weak self] in
            self?._setAmbientVolume(volume, fadeDuration: fadeDuration)
        }
    }

    private func _setAmbientVolume(_ target: Float, fadeDuration: TimeInterval) {
        ambientFadeWorkItem?.cancel()
        guard let player = ambientPlayer else { return }
        if abs(player.volume - target) < 0.01 { return }
        let start = player.volume
        let steps = max(1, Int(fadeDuration / 0.05))
        let stepDuration = fadeDuration / Double(steps)
        let stepValue = (target - start) / Float(steps)
        func runStep(_ step: Int) {
            ambientPlayer?.volume = min(1, max(0, start + Float(step) * stepValue))
            guard step < steps else { return }
            let next = step + 1
            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                _ = self
                runStep(next)
            }
            ambientFadeWorkItem = work
            queue.asyncAfter(deadline: .now() + stepDuration, execute: work)
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            _ = self
            runStep(1)
        }
        ambientFadeWorkItem = work
        queue.asyncAfter(deadline: .now() + stepDuration, execute: work)
    }

    func playStream(_ pcmData: Data) {
        queue.async { [weak self] in
            self?._schedule(pcmData)
        }
    }

    private func _schedule(_ pcmData: Data) {
        guard engine.isRunning else {
            DispatchQueue.main.async { MobiEngine.shared.setActivityState(.idle) }
            print("[AudioPlayer] Engine not running; releasing mic gate to .idle")
            return
        }
        let frameCount = pcmData.count / 2
        guard frameCount > 0 else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            DispatchQueue.main.async { MobiEngine.shared.setActivityState(.idle) }
            return
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        guard let channelData = buffer.int16ChannelData else {
            DispatchQueue.main.async { MobiEngine.shared.setActivityState(.idle) }
            return
        }
        pcmData.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { return }
            memcpy(channelData[0], base, pcmData.count)
        }
        let duration = Double(frameCount) / format.sampleRate
        drainLock.lock()
        scheduledBufferCount += 1
        totalScheduledDuration += duration
        let isFirst = (scheduledBufferCount == 1)
        let firstCallback = isFirst ? onFirstBufferScheduled : nil
        if isFirst { onFirstBufferScheduled = nil }
        drainLock.unlock()
        firstCallback?()
        playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            self?.didFinishPlaybackBuffer(playedDuration: duration)
        }
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private func didFinishPlaybackBuffer(playedDuration: TimeInterval) {
        drainLock.lock()
        scheduledBufferCount -= 1
        totalScheduledDuration = max(0, totalScheduledDuration - playedDuration)
        let count = scheduledBufferCount
        let callback = (count == 0) ? onPlaybackQueueDrain : nil
        onPlaybackQueueDrain = nil
        drainLock.unlock()
        if let callback {
            DispatchQueue.main.async { callback() }
        }
        if count == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.outputLevel = 0
            }
        }
    }

    /// 当前队列预计还需播放的秒数（no_content 时用于「剩余时长+0.2s」开麦）
    func estimatedRemainingPlaybackTime() -> TimeInterval {
        drainLock.lock()
        let t = totalScheduledDuration
        drainLock.unlock()
        return t
    }

    /// 播放队列排空时执行 callback（用于 no_content 后「真正播完再开麦」）；若当前已空则立即执行。
    func notifyWhenQueueDrains(callback: @escaping () -> Void) {
        drainLock.lock()
        if scheduledBufferCount == 0 {
            drainLock.unlock()
            DispatchQueue.main.async { callback() }
            return
        }
        onPlaybackQueueDrain = callback
        drainLock.unlock()
    }

    func stop() {
        queue.async { [weak self] in
            self?.playerNode.stop()
        }
    }

    /// Stops ambient playback (e.g. Genesis loop) when video takes over.
    func stopAmbient() {
        queue.async { [weak self] in
            self?.ambientPlayer?.stop()
        }
    }

    /// Play a one-shot sound (e.g. land_thud, squeak). Skips silently if file not found.
    func playOneShot(resource: String, ext: String = "mp3", subdirectory: String? = "Resources/Audio") {
        queue.async { [weak self] in
            self?._playOneShot(resource: resource, ext: ext, subdirectory: subdirectory)
        }
    }

    private func _playOneShot(resource: String, ext: String, subdirectory: String?) {
        let url = subdirectory.map { Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: $0) }
            ?? Bundle.main.url(forResource: resource, withExtension: ext)
            ?? Bundle.main.url(forResource: resource, withExtension: ext.uppercased(), subdirectory: "Resources/Audio")
        guard let url = url else {
            print("[AudioPlayer] One-shot '\(resource).\(ext)' not found, skipping.")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.8
            player.prepareToPlay()
            player.play()
        } catch {
            print("[AudioPlayer] One-shot play failed: \(error)")
        }
    }

    /// Call when playback fails so the mic gate can open (activity state leaves .speaking).
    func releaseSpeakingStateOnError() {
        Task { @MainActor in
            let state = MobiEngine.shared.activityState
            if state == .speaking || state == .thinking {
                MobiEngine.shared.setActivityState(.idle)
                print("[AudioPlayer] Playback error; released activity state to .idle for mic gate")
            }
        }
    }
}

