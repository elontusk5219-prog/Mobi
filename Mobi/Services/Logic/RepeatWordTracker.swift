//
//  RepeatWordTracker.swift
//  Mobi
//
//  学说话「教会」：检测用户重复同一词 2–3 次，按可变奖励概率判定模仿成功。设计见 newborn 学说话上瘾计划。
//

import Foundation

/// 追踪用户近期发言，检测重复词并返回「教会」判定。
struct RepeatWordTracker {
    private var recentUtterances: [String] = []
    private let maxRecent = 20
    private let keyLength = 8

    /// 从发言中提取作为「词」的 key（前 N 字/词）
    private func key(from utterance: String) -> String {
        let trimmed = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        let first = String(trimmed.prefix(keyLength))
        return first.lowercased()
    }

    mutating func addUtterance(_ text: String) -> (success: Bool, word: String?) {
        let k = key(from: text)
        guard !k.isEmpty else { return (false, nil) }

        recentUtterances.append(k)
        if recentUtterances.count > maxRecent {
            recentUtterances.removeFirst(recentUtterances.count - maxRecent)
        }

        let count = recentUtterances.filter { $0 == k }.count
        guard count >= 2 else { return (false, nil) }

        let word = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(keyLength))
        guard !word.isEmpty else { return (false, nil) }

        let roll = Double.random(in: 0..<1)
        let threshold: Double
        switch count {
        case 2: threshold = 0.30
        case 3: threshold = 0.70
        default: threshold = 1.0
        }
        if roll < threshold {
            return (true, word)
        }
        return (false, nil)
    }

    mutating func reset() {
        recentUtterances.removeAll()
    }
}
