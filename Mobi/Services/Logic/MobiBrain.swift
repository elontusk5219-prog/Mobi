//
//  MobiBrain.swift
//  Mobi
//
//  Room 阶段大脑：刺激 → 6 维度 + decay → 派生状态 → 行为输出。设计见 docs/Mobi阶段大脑与意识驱动设计.md
//

import Foundation
import SwiftUI
import Combine

/// 用户方向（屏幕偏下），用于 voice 时 attentionTarget
private let userDirection = CGSize(width: 0, height: 30)

/// seeking 判定：沉默超过此秒数且 arousal 在中段
private let seekingSilenceThreshold: TimeInterval = 12.0
private let seekingArousalLow: Double = 0.3
private let seekingArousalHigh: Double = 0.7

/// startled 持续时长
private let startledDuration: TimeInterval = 0.5

/// 每 tick decay 指数底（0.98^deltaSeconds）
private let decayPerSecond: Double = 0.98

@MainActor
final class MobiBrain: ObservableObject {

    // MARK: - 状态（对外只读）

    @Published private(set) var state: MobiBrainState
    @Published private(set) var derivedState: MobiDerivedState = .none
    @Published private(set) var isSeeking: Bool = false
    @Published private(set) var isStartled: Bool = false

    /// 呼吸幅度倍数（arousal 高→1.2–1.3，低→0.7–0.8）
    @Published private(set) var breathScaleMultiplier: Double = 1.0
    /// 呼吸频率倍数（arousal 高→1.3，低→0.7）
    @Published private(set) var breathFrequencyMultiplier: Double = 1.0

    /// 当前沉默时长（由 Room 在 tick 前通过 receiveSilence 注入，用于派生 seeking）
    private var currentSilenceDuration: TimeInterval = 0

    private var startledUntil: Date?

    // MARK: - Init

    /// attachment 初值来自 EvolutionManager.intimacyLevel/100
    init(attachmentFromIntimacyLevel intimacyLevel: Int = 0) {
        self.state = .initial(attachmentFromIntimacy: intimacyLevel)
        updateDerivedAndOutputs()
    }

    // MARK: - Tick（decay + 派生状态）

    /// 每 50–100ms 调用一次。先由 Room 调用各 receive* 注入本帧刺激，再调用 tick。
    func tick(deltaTime: TimeInterval) {
        applyDecay(deltaTime: deltaTime)
        state.clampAll()
        updateStartled(now: Date())
        updateDerivedAndOutputs()
    }

    private func applyDecay(deltaTime: TimeInterval) {
        let factor = pow(decayPerSecond, deltaTime)
        state.arousal *= factor
        state.attachment *= factor
        state.curiosity *= factor
        state.comfort *= factor
        state.energy *= factor
        state.attentionLevel *= factor
        // attentionTarget 缓慢回零（由 View lerp 更自然，这里做简单衰减）
        state.attentionTarget.width *= factor
        state.attentionTarget.height *= factor
    }

    private func updateStartled(now: Date) {
        if let until = startledUntil, now >= until {
            startledUntil = nil
        }
        isStartled = startledUntil != nil
    }

    private func updateDerivedAndOutputs() {
        let s = state
        currentSilenceDuration = max(0, currentSilenceDuration)

        // 派生状态优先级：startled > seeking > drowsy > alert > bonded > curious > content > none
        if isStartled {
            derivedState = .startled
        } else if currentSilenceDuration >= seekingSilenceThreshold,
                  s.arousal >= seekingArousalLow, s.arousal <= seekingArousalHigh {
            derivedState = .seeking
            isSeeking = true
        } else {
            isSeeking = false
            if s.arousal < 0.3, s.energy < 0.4 {
                derivedState = .drowsy
            } else if s.arousal > 0.6, s.attentionLevel > 0.3 {
                derivedState = .alert
            } else if s.attachment > 0.7 {
                derivedState = .bonded
            } else if s.curiosity > 0.5, s.comfort > 0.4 {
                derivedState = .curious
            } else if s.comfort > 0.6, s.arousal < 0.5 {
                derivedState = .content
            } else {
                derivedState = .none
            }
        }

        // 行为输出：呼吸
        if s.arousal > 0.6 {
            breathScaleMultiplier = 1.0 + (s.arousal - 0.6) * 0.75   // 约 1.0–1.3
            breathFrequencyMultiplier = 1.3
        } else if s.arousal < 0.3 {
            breathScaleMultiplier = 0.7 + s.arousal * 0.5            // 约 0.85–0.85
            breathFrequencyMultiplier = 0.7
        } else {
            breathScaleMultiplier = 1.0
            breathFrequencyMultiplier = 1.0
        }
    }

    // MARK: - 刺激注入（由 Room 每 tick 或事件时调用）

    /// 用户说话音量 0–1，每 tick 调用
    func receiveVoice(presence: Float, deltaTime: TimeInterval) {
        guard presence > 0.01 else { return }
        let p = Double(presence)
        state.arousal += 0.15 * p * deltaTime
        state.attachment += 0.02 * p * deltaTime
        state.curiosity += 0.1 * p * deltaTime
        state.energy -= 0.01 * p * deltaTime
        state.attentionTarget = userDirection
        state.attentionLevel = min(1.0, state.attentionLevel + 0.2 * deltaTime)
    }

    /// 戳击：轻戳或重戳，一次调用
    func receiveTouchPoke(light: Bool, location: CGSize) {
        if light {
            state.arousal += 0.1
            state.attachment += 0.05
            state.curiosity += 0.05
            state.comfort -= 0.02
        } else {
            state.arousal += 0.2
            state.comfort -= 0.1
            startledUntil = Date().addingTimeInterval(startledDuration)
        }
        state.attentionTarget = CGSize(
            width: min(20, max(-20, location.width)),
            height: min(20, max(-20, location.height))
        )
        state.attentionLevel = 0.8
        state.clampAll()
    }

    /// 拖拽持续中，每 tick 调用
    func receiveTouchDrag(direction: CGSize, deltaTime: TimeInterval) {
        state.arousal += 0.05 * deltaTime
        state.attachment += 0.03 * deltaTime
        state.comfort += 0.02 * deltaTime
        state.energy -= 0.005 * deltaTime
        let d = CGSize(
            width: min(20, max(-20, direction.width * 0.1)),
            height: min(20, max(-20, direction.height * 0.1))
        )
        state.attentionTarget = d
        state.attentionLevel = 0.7
    }

    /// 当前沉默时长（秒），每 tick 调用；用于 decay 与 seeking 判定
    func receiveSilence(duration: TimeInterval, deltaTime: TimeInterval) {
        currentSilenceDuration = duration
        if duration >= 15 {
            state.arousal -= 0.03 * deltaTime
            state.curiosity += 0.05 * deltaTime
            state.energy += 0.02 * deltaTime
        } else if duration >= 5 {
            state.arousal -= 0.02 * deltaTime
            state.curiosity += 0.03 * deltaTime
            state.energy += 0.01 * deltaTime
        }
    }

    /// AI 正在说话，每 tick 调用
    func receiveAISpeaking(deltaTime: TimeInterval) {
        state.arousal += 0.05 * deltaTime
        state.energy -= 0.02 * deltaTime
    }

    /// 关键词一次注入
    func receiveKeyword(_ keyword: String) {
        if keyword.contains("累") {
            state.arousal -= 0.1
            state.attachment += 0.05
            state.comfort += 0.05
            state.energy -= 0.2
        } else if keyword.contains("咖啡") {
            state.arousal += 0.1
            state.curiosity += 0.15
            state.energy += 0.1
        }
        state.clampAll()
    }

    /// 重置沉默计时（用户开口或触摸后由 Room 调用，便于 seeking 冷却）
    func resetSilenceForNewInteraction() {
        currentSilenceDuration = 0
    }

    // MARK: - 状态觉察注入（P3-4：注入 sendTextInstruction / prompt）

    /// 当前大脑状态的自然语言描述，用于注入 LLM 指令，使回复更贴合当下状态。
    var stateContextForPrompt: String {
        let a = state.arousal
        let arousalDesc = a < 0.35 ? "low" : (a > 0.65 ? "high" : "medium")
        let att = state.attentionLevel > 0.5 ? "focused" : "relaxed"
        return "You are in a \(derivedState.rawValue) state. Arousal: \(arousalDesc). Attention: \(att)."
    }
}
