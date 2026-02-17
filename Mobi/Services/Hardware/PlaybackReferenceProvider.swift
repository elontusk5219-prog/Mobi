//
//  PlaybackReferenceProvider.swift
//  Mobi
//
//  用于「背景乐与用户语音分离」：上行给 Doubao 的麦克风信号可减去当前播放参考，减少背景乐串音。
//

import Foundation
import AVFoundation

/// 提供当前播放参考（如氛围乐）的 PCM，供麦克风管线做减除，实现简单 AEC/分离。
protocol PlaybackReferenceProvider: AnyObject {
    /// 返回最近一段播放的 float 单声道样本（与麦克风采样率一致时可直接减除）。count 为样本数。
    func getPlaybackReference(frameCount: Int) -> [Float]?
}
