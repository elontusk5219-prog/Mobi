//
//  AudioVisualizerService.swift
//  Mobi
//
//  Mic: amplitude for UI + 16k mono PCM (s16le) for Doubao uplink.
//

import Foundation
import AVFoundation
import Combine

/// 上行给 Doubao 前可减去「播放参考」，实现背景乐与语音分离。传入 (frameCount) -> 最近 frameCount 个 float 样本，nil 表示不分离。
typealias PlaybackReferenceProviderBlock = (Int) -> [Float]?

final class AudioVisualizerService: ObservableObject {
    @Published private(set) var normalizedPower: Float = 0.0

    private let engine = AVAudioEngine()
    private var isMonitoring = false
    private var pcm16kAccumulator = Data()
    private let doubaoChunkSize = 320
    private var powerUpdateCounter: Int = 0
    /// 若设置，processBuffer 会在转 16k 前用麦克风减去该参考（gain 约 0.25），减少背景乐串音。
    var playbackReferenceProvider: PlaybackReferenceProviderBlock?

    /// Half-duplex mic gate: when true, drop all capture and do not send to WebSocket (prevents echo loop).
    private let muteLock = NSLock()
    private var _isInputMuted: Bool = false
    public var isInputMuted: Bool {
        get {
            muteLock.lock()
            defer { muteLock.unlock() }
            return _isInputMuted
        }
        set {
            muteLock.lock()
            defer { muteLock.unlock() }
            _isInputMuted = newValue
        }
    }

    func startMonitoring() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            return
        }
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?._startEngine() }
            }
        } else {
            session.requestRecordPermission { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?._startEngine() }
            }
        }
        #else
        _startEngine()
        #endif
    }

    private func _startEngine() {
        guard !isMonitoring else { return }
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else { return }

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }
        do {
            engine.prepare()
            try engine.start()
            isMonitoring = true
        } catch {
            inputNode.removeTap(onBus: 0)
        }
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        if isInputMuted {
            pcm16kAccumulator.removeAll()
            return
        }
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        let channelCount = Int(buffer.format.channelCount)

        if let ref = playbackReferenceProvider?(frameLength), ref.count >= frameLength {
            let gain: Float = 0.25
            for i in 0..<frameLength {
                channelData[i] = channelData[i] - gain * ref[i]
            }
        }

        var sum: Float = 0
        for i in 0..<frameLength { sum += channelData[i] * channelData[i] }
        let rms = frameLength > 0 ? sqrt(sum / Float(frameLength)) : 0
        let normalized = min(1.0, rms * 8)
        powerUpdateCounter += 1
        if powerUpdateCounter % 4 == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.normalizedPower = normalized
            }
        }

        let pcm16 = floatTo16kMonoS16LE(channelData, frameLength: frameLength, sampleRate: sampleRate, channelCount: channelCount)
        pcm16kAccumulator.append(pcm16)
        while pcm16kAccumulator.count >= doubaoChunkSize {
            let chunk = pcm16kAccumulator.prefix(doubaoChunkSize)
            pcm16kAccumulator.removeFirst(doubaoChunkSize)
            DoubaoRealtimeService.shared.sendAudioBuffer(Data(chunk))
        }
    }

    /// Resample to 16kHz mono and convert float [-1,1] to s16le.
    private func floatTo16kMonoS16LE(_ src: UnsafeMutablePointer<Float>, frameLength: Int, sampleRate: Float, channelCount: Int) -> Data {
        let ratio = sampleRate / 16000
        let outCount = Int(Float(frameLength) / ratio)
        var out = Data(capacity: outCount * 2)
        for i in 0..<outCount {
            let fi = Float(i) * ratio
            let idx = min(Int(fi), frameLength - 1)
            let sample = max(-1, min(1, src[idx]))
            var s16 = Int16(sample * 32767).littleEndian
            out.append(withUnsafeBytes(of: &s16) { Data($0) })
        }
        return out
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isMonitoring = false
        normalizedPower = 0
    }
}
