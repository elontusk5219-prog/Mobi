//
//  MobiEnums.swift
//  Mobi
//

import Foundation

enum LifeStage: String, CaseIterable, Sendable {
    case genesis
    case newborn
    case child
    case adult
}

/// Visual state for AminaFluidView: drives listening (absorbing) vs speaking (projecting) physics.
enum AnimaState: String, CaseIterable, Sendable {
    case idle
    case listening  // User is talking
    case speaking   // AI is talking
}

enum ActivityState: String, CaseIterable, Sendable {
    case idle
    case listening
    case thinking
    case speaking
    case sleeping
    /// Proactive: user idle > 15s, Mobi "seeking" / drifting.
    case seeking
}

/// AI mood for ambient audio DSP (pitch, speed, reverb, EQ).
enum MobiMood: String, CaseIterable, Sendable {
    case neutral
    case happy
    case sad
    case anxious
    case thinking
}

/// Genesis visual phase (Luminous Void → Snap).
enum GenesisPhase: String, CaseIterable, Sendable {
    case luminousVoid  // 纯白初始
    case filling       // 对话注入
    case converging    // 向互补色收敛
    case theSnap       // 神圣坍缩
}
