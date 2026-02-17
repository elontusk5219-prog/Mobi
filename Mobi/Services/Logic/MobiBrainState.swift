//
//  MobiBrainState.swift
//  Mobi
//
//  大脑状态模型：6 维度 + 注意力目标 + 派生状态。设计见 docs/Mobi阶段大脑与意识驱动设计.md
//

import Foundation
import CoreGraphics

// MARK: - 派生状态（从核心维度 + silence 推导）

enum MobiDerivedState: String, CaseIterable, Sendable {
    case alert      // arousal 高、attention 有目标
    case drowsy    // arousal 低、energy 低
    case curious   // curiosity 高、comfort 够
    case seeking   // arousal 中、长时间无互动
    case bonded    // attachment 高
    case startled  // 突然大音量/用力戳，短暂
    case content   // comfort 高、arousal 低
    case none      // 无突出派生状态
}

// MARK: - 核心状态（0.0–1.0，带 decay）

struct MobiBrainState {
    var arousal: Double
    var attachment: Double
    var curiosity: Double
    var comfort: Double
    var energy: Double
    /// 注意力目标方向（供 View 做 lerp；或由 View 完全负责算 lookTarget）
    var attentionTarget: CGSize
    /// 注意力强度 0–1
    var attentionLevel: Double

    static func clamped(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    /// 所有标量维度 clamp 到 [0, 1]
    mutating func clampAll() {
        arousal = Self.clamped(arousal)
        attachment = Self.clamped(attachment)
        curiosity = Self.clamped(curiosity)
        comfort = Self.clamped(comfort)
        energy = Self.clamped(energy)
        attentionLevel = Self.clamped(attentionLevel)
    }

    /// 初始状态：attachment 由 EvolutionManager.intimacyLevel/100 提供，其余中性
    static func initial(attachmentFromIntimacy intimacyLevel: Int) -> MobiBrainState {
        let attachment = Self.clamped(Double(intimacyLevel) / 100.0)
        return MobiBrainState(
            arousal: 0.5,
            attachment: attachment,
            curiosity: 0.5,
            comfort: 0.6,
            energy: 0.6,
            attentionTarget: .zero,
            attentionLevel: 0.5
        )
    }
}
