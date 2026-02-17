//
//  NewbornSpeechPhase.swift
//  Mobi
//
//  newborn 学说话阶梯：完全静默 → 单音节试探 → 鹦鹉学舌 → 简单词句。设计见 newborn 学说话上瘾计划。
//

import Foundation

/// newborn 阶段学说话阶梯；由铭印数 + 用户输入历史推导。
enum NewbornSpeechPhase {
    /// 完全静默：0 铭印，Mobi 不说任何话，只做表情/肢体/拟声（咕、嗯）
    case mute
    /// 单音节试探：开始发出 gibberish（ba、bo、nya）回应
    case gibberish
    /// 鹦鹉学舌：听到重复词后尝试模仿；2–3 次内随机成功
    case mimic
    /// 简单词句：能说出已学会的词，并混入 1–2 个新词试探
    case simpleWords

    /// 由铭印数 + 是否已听过用户说话推导阶段。0 铭印且未听过用户 = mute；0 铭印且已听过 = gibberish；1+ 铭印 = simpleWords。
    static func from(imprintCount: Int, hasHeardUserSpeech: Bool) -> NewbornSpeechPhase {
        switch imprintCount {
        case 0:
            return hasHeardUserSpeech ? .gibberish : .mute
        default:
            return .simpleWords
        }
    }

    /// 当前 Phase（用于 RoomContainerView 设置 shouldSuppressTTS）；需在 MainActor 调用
    @MainActor
    static func current() -> NewbornSpeechPhase {
        guard EvolutionManager.shared.effectiveStage == .newborn else { return .simpleWords }
        let count = ImprintService.getCurrentUserImprints().count
        let heard = NewbornSpeechState.currentUserHasHeardUserSpeech
        return from(imprintCount: count, hasHeardUserSpeech: heard)
    }

    /// 是否禁止 TTS 输出（仅视觉反馈）
    var suppressesTTS: Bool {
        self == .mute
    }

    /// 是否禁止 seeking 主动说话（mute 时 Mobi 完全静默）
    var suppressesSeeking: Bool {
        self == .mute
    }
}
