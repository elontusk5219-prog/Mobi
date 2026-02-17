//
//  KuroVoiceSynthesizer.swift
//  Mobi
//
//  库洛语程序化语音：根据 gibberish 音节序列用代码合成短 tone 并按序播放，无音频资源。
//

import AVFoundation
import Foundation

final class KuroVoiceSynthesizer {
    static let shared = KuroVoiceSynthesizer()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let toneDuration: Double = 0.07
    private let gapDuration: Double = 0.04
    private let pauseDuration: Double = 0.10
    private let volume: Float = 0.2

    private init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    /// 音节 -> 频率（偏冷、略低）
    private func frequency(for syllable: String) -> Float {
        let table: [String: Float] = [
            "Krr": 180, "Zt": 220, "Vz": 260, "Tk": 200, "Nn": 240,
            "Kt": 190, "Px": 270, "Qv": 210, "Pk": 230, "Pr": 250
        ]
        return table[syllable] ?? 220
    }

    /// 生成一段正弦波 PCM buffer
    private func makeToneBuffer(frequency: Float, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(Int(duration * sampleRate))
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        guard let ch = buf.floatChannelData?[0] else { return nil }
        let sr = Float(sampleRate)
        for i in 0..<Int(frameCount) {
            let t = Float(i) / sr
            ch[i] = volume * sin(2 * .pi * frequency * t)
        }
        return buf
    }

    /// 生成静音 buffer
    private func makeSilenceBuffer(duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(Int(duration * sampleRate))
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        if let ch = buf.floatChannelData?[0] {
            for i in 0..<Int(frameCount) { ch[i] = 0 }
        }
        return buf
    }

    /// 播放库洛语：输入 gibberish 字符串，解析音节后按序合成并播放（at: nil 即顺序排队）
    func speak(_ gibberishString: String) {
        stop()
        let tokens = KuroGibberishGenerator.syllables(for: gibberishString)
        guard !tokens.isEmpty else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        do {
            try engine.start()
        } catch {
            return
        }
        let isPause: (String) -> Bool = { $0 == "—" || $0 == "…" }
        for token in tokens {
            if isPause(token) {
                guard let sil = makeSilenceBuffer(duration: pauseDuration, format: format) else { continue }
                playerNode.scheduleBuffer(sil, at: nil, options: []) { }
            } else {
                let freq = frequency(for: token)
                guard let tone = makeToneBuffer(frequency: freq, duration: toneDuration, format: format),
                      let gap = makeSilenceBuffer(duration: gapDuration, format: format) else { continue }
                playerNode.scheduleBuffer(tone, at: nil, options: []) { }
                playerNode.scheduleBuffer(gap, at: nil, options: []) { }
            }
        }
        playerNode.play()
    }

    func stop() {
        playerNode.stop()
        playerNode.reset()
    }
}
