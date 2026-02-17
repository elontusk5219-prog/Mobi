//
//  UserPsycheModel.swift
//  Mobi
//
//  Soul Casting Protocol: real-time psyche dimensions (Warmth, Energy, Chaos)
//  driven by user input for the Amina sphere visual evolution.
//

import Foundation
import NaturalLanguage
import SwiftUI
import Combine

// MARK: - UserProfileDraft (Shadow Profiler: cold-reading energy / intimacy / color)

/// Real-time draft for 10s commit. Updated from user replies and METADATA. 0–100 scale for energy/intimacy.
struct UserProfileDraft {
    var energy: Int   // 0–100; low = 累, high = 刚开始
    var intimacy: Int  // 0–100; low = 保持距离, high = 靠近
    var colorId: String?  // MobiColorPalette rawValue; nil until user answers color question
    /// Shadow Analysis: latest round analyst note.
    var thoughtProcess: String?
    var currentMood: String?
    var openness: String?
    var communicationStyle: String?
    var shellType: String?
    var personalityBase: String?

    static let `default` = UserProfileDraft(energy: 50, intimacy: 50, colorId: nil, thoughtProcess: nil, currentMood: nil, openness: nil, communicationStyle: nil, shellType: nil, personalityBase: nil)
}

// MARK: - SoulProfile (Final stats for LLM "First Room Item")

struct SoulProfile: Codable {
    let warmth: Double
    let energy: Double
    let chaos: Double
    let conversationTurn: Int
    let sessionSummary: String?
    /// Cold-reading draft for commit (energy/intimacy 0–100, colorId from palette).
    let draftEnergy: Int?
    let draftIntimacy: Int?
    let draftColorId: String?
    /// Shadow Analysis draft fields for GeminiVisualDNA.
    let draftMood: String?
    let draftOpenness: String?
    let draftCommunicationStyle: String?
    let draftShellType: String?
    let draftPersonalityBase: String?
    let shadowSummary: String?

    init(warmth: Double, energy: Double, chaos: Double, conversationTurn: Int, sessionSummary: String?,
         draftEnergy: Int? = nil, draftIntimacy: Int? = nil, draftColorId: String? = nil,
         draftMood: String? = nil, draftOpenness: String? = nil, draftCommunicationStyle: String? = nil,
         draftShellType: String? = nil, draftPersonalityBase: String? = nil, shadowSummary: String? = nil) {
        self.warmth = warmth
        self.energy = energy
        self.chaos = chaos
        self.conversationTurn = conversationTurn
        self.sessionSummary = sessionSummary
        self.draftEnergy = draftEnergy
        self.draftIntimacy = draftIntimacy
        self.draftColorId = draftColorId
        self.draftMood = draftMood
        self.draftOpenness = draftOpenness
        self.draftCommunicationStyle = draftCommunicationStyle
        self.draftShellType = draftShellType
        self.draftPersonalityBase = draftPersonalityBase
        self.shadowSummary = shadowSummary
    }

    var rgbOfSoul: (r: Double, g: Double, b: Double) {
        let r = warmth
        let g = warmth * 0.6
        let b = 1.0 - warmth
        return (r, g, b)
    }

    func toJSONSummary() -> String {
        var dict: [String: Any] = [
            "warmth": warmth,
            "energy": energy,
            "chaos": chaos,
            "conversationTurn": conversationTurn,
            "sessionSummary": sessionSummary ?? "",
            "rgbOfSoul": ["r": rgbOfSoul.r, "g": rgbOfSoul.g, "b": rgbOfSoul.b]
        ]
        if let e = draftEnergy { dict["draftEnergy"] = e }
        if let i = draftIntimacy { dict["draftIntimacy"] = i }
        if let c = draftColorId { dict["draftColorId"] = c }
        if let m = draftMood { dict["draftMood"] = m }
        if let o = draftOpenness { dict["draftOpenness"] = o }
        if let s = draftCommunicationStyle { dict["draftCommunicationStyle"] = s }
        if let t = draftShellType { dict["draftShellType"] = t }
        if let p = draftPersonalityBase { dict["draftPersonalityBase"] = p }
        if let ss = shadowSummary { dict["shadowSummary"] = ss }
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}

// MARK: - UserPsycheModel

/// Total turns for Soul Casting / Sensory Progression (0.0 → 1.0). Genesis V3: 15-turn hunting journey.
let kSensoryProgressionTotalTurns = 15

@MainActor
final class UserPsycheModel: ObservableObject {
    private var _warmth: Double = 0.5
    private var _energy: Double = 0.5
    private var _chaos: Double = 0.5
    /// Always clamped 0.0–1.0 to prevent vanishing orb / invalid visuals.
    var warmth: Double {
        get { _warmth }
        set { let c = min(max(newValue, 0), 1); if _warmth != c { objectWillChange.send(); _warmth = c } }
    }
    var energy: Double {
        get { _energy }
        set { let c = min(max(newValue, 0), 1); if _energy != c { objectWillChange.send(); _energy = c } }
    }
    var chaos: Double {
        get { _chaos }
        set { let c = min(max(newValue, 0), 1); if _chaos != c { objectWillChange.send(); _chaos = c } }
    }
    @Published var conversationTurn: Int = 0

    /// Shadow Profiler draft: energy/intimacy/colorId updated from cold-reading answers and METADATA.
    @Published private(set) var profileDraft: UserProfileDraft = .default
    /// Multi-turn thought_process from Shadow Analysis (for shadowSummary in SoulProfile).
    @Published private(set) var shadowThoughtProcesses: [String] = []

    /// Normalized progress 0.0–1.0 for Sensory Progression (currentTurn / totalTurns).
    var sensoryProgress: Double {
        min(1.0, Double(conversationTurn) / Double(kSensoryProgressionTotalTurns))
    }

    /// Dominant color from current warmth (blue 0 ↔ orange 1). For ComplementaryEngine / ColorInversionLab.
    var dominantColor: Color {
        let w = min(1, max(0, warmth))
        return Color(
            red: (1 - w) * 0.2 + w * 1.0,
            green: (1 - w) * 0.4 + w * 0.5,
            blue: (1 - w) * 1.0 + w * 0.1
        )
    }

    /// Session transcript snippets for final summary (optional, for LLM context).
    @Published private(set) var sessionTranscriptSnippets: [String] = []
    /// Warmth at each turn (for weighted average complement). Last 15.
    @Published private(set) var turnWarmths: [Double] = []

    private let driftStrength: Double = 0.12
    private let smoothing: Double = 0.35
    private let sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])

    private static let chaosIncreaseKeywords: Set<String> = [
        "cloud", "water", "dream", "change", "flow", "wind", "soft", "float", "mist"
    ]
    private static let chaosDecreaseKeywords: Set<String> = [
        "stone", "forever", "rule", "protect", "solid", "fixed", "clear", "order"
    ]

    /// Cold-reading: user says 累 / tired → low energy. 刚开始 / just started → high energy.
    private static let energyLowKeywords: Set<String> = ["累", "累坏了", "很累", "tired", "exhausted", "困"]
    private static let energyHighKeywords: Set<String> = ["刚开始", "刚刚开始", "才刚开始", "just started", "fresh"]
    /// Cold-reading: 靠近 / 近 → high intimacy. 距离 / 远 / 保持 → low intimacy.
    private static let intimacyHighKeywords: Set<String> = ["靠近", "近", "近一点", "过来", "closer", "near"]
    private static let intimacyLowKeywords: Set<String> = ["距离", "远", "远一点", "保持距离", "away", "distance"]

    // MARK: - Soul Hook keywords (trigger visual pulse; 灵魂钩子词库)

    /// Keyword -> associated pulse color (ink-in-milk). Order defines priority (first match wins).
    private static let soulHookKeywords: [(String, Color)] = [
        ("累", Color(red: 0.45, green: 0.52, blue: 0.65)),
        ("孤独", Color(red: 0.29, green: 0.22, blue: 0.49)),
        ("期待", Color(red: 0.95, green: 0.75, blue: 0.35)),
        ("光", Color(red: 0.98, green: 0.92, blue: 0.72)),
        ("风", Color(red: 0.40, green: 0.85, blue: 0.78))
    ]

    /// Scan input for soul-hook keywords; returns associated pulse color for first match. Caller (ViewModel) triggers visual pulse.
    static func scanForSoulHookPulseColor(in text: String) -> Color? {
        let lower = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else { return nil }
        for (keyword, color) in soulHookKeywords {
            if lower.contains(keyword) { return color }
        }
        return nil
    }

    /// Dismissive phrases: user defers or gives minimal response. Triggers stronger nudge.
    private static let dismissivePhrases: Set<String> = [
        "嗯", "好", "哦", "啊", "呃", "唉", "唔", "好吧", "好的", "好呀", "好啊", "可以",
        "随便", "都行", "都可以", "无所谓", "不知道", "没想好", "你定", "你决定", "你说了算",
        "听你的", "你看着办", "你说呢", "ok", "嗯嗯", "对", "是的", "是啊", "没", "没有",
        "随便吧", "都可以吧", "无所谓啦", "好啊", "行", "行吧", "中", "好哦"
    ]

    /// Whether user input is "reserved" (very short or dismissive). When true, LLM instruction should add nudge to draw them out.
    static func isReservedUserInput(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count < 15 { return true }
        return dismissivePhrases.contains(t.lowercased())
    }

    /// Update psyche dimensions from user input text and optional audio amplitude; apply smoothing.
    /// - Parameter audioAmplitude: 0...1 from AudioVisualizerService.normalizedPower (peak/avg during utterance).
    func updateRealtime(inputText: String, audioAmplitude: Float = 0) {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let targetWarmth = computeWarmthTarget(inputText: inputText)
        let targetEnergy = computeEnergyTarget(inputText: inputText, audioAmplitude: audioAmplitude)
        let targetChaos = computeChaosTarget(inputText: inputText)

        let newWarmth = lerp(current: warmth, target: targetWarmth, factor: smoothing)
        let newEnergy = lerp(current: energy, target: targetEnergy, factor: smoothing)
        let newChaos = lerp(current: chaos, target: targetChaos, factor: smoothing)

        withAnimation(.easeOut(duration: 0.4)) {
            warmth = newWarmth
            energy = newEnergy
            chaos = newChaos
        }

        sessionTranscriptSnippets.append(String(inputText.prefix(200)))
        if sessionTranscriptSnippets.count > 20 {
            sessionTranscriptSnippets.removeFirst()
        }

        applyDraftFromUserInput(inputText)
    }

    /// Update profileDraft from cold-reading METADATA (Shadow Analysis + energy/intimacy/color).
    func updateDraftFromMetadata(_ draft: MetadataDraftUpdate) {
        var next = profileDraft
        if let tag = draft.energyTag?.lowercased() {
            if tag == "low" { next.energy = max(0, next.energy - 30) }
            if tag == "high" { next.energy = min(100, next.energy + 30) }
        }
        if let tag = draft.intimacyTag?.lowercased() {
            if tag == "low" { next.intimacy = max(0, next.intimacy - 30) }
            if tag == "high" { next.intimacy = min(100, next.intimacy + 30) }
        }
        if let c = draft.colorId, !c.isEmpty, MobiColorPalette.resolveToHex(c) != nil {
            next.colorId = MobiColorPalette.resolveToPaletteId(c) ?? c
        }
        if let v = draft.thoughtProcess, !v.isEmpty {
            next.thoughtProcess = v
            shadowThoughtProcesses.append(v)
            if shadowThoughtProcesses.count > 20 { shadowThoughtProcesses.removeFirst() }
        }
        if let v = draft.currentMood { next.currentMood = v }
        if let v = draft.openness { next.openness = v }
        if let v = draft.communicationStyle { next.communicationStyle = v }
        if let v = draft.shellType { next.shellType = v }
        if let v = draft.personalityBase { next.personalityBase = v }
        profileDraft = next
    }

    /// Update draft from user speech (keywords: 累, 靠近, 远, etc.).
    private func applyDraftFromUserInput(_ inputText: String) {
        let lower = inputText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else { return }
        var next = profileDraft
        for w in Self.energyLowKeywords where lower.contains(w) {
            next.energy = max(0, next.energy - 25)
            break
        }
        for w in Self.energyHighKeywords where lower.contains(w) {
            next.energy = min(100, next.energy + 25)
            break
        }
        for w in Self.intimacyHighKeywords where lower.contains(w) {
            next.intimacy = min(100, next.intimacy + 25)
            break
        }
        for w in Self.intimacyLowKeywords where lower.contains(w) {
            next.intimacy = max(0, next.intimacy - 25)
            break
        }
        profileDraft = next
    }

    func incrementTurn() {
        conversationTurn += 1
        turnWarmths.append(min(1, max(0, warmth)))
        if turnWarmths.count > kSensoryProgressionTotalTurns {
            turnWarmths.removeFirst()
        }
    }

    /// Weighted average warmth over turns (later turns weight more). For ColorInversionLab theme complement.
    var weightedAverageWarmth: Double {
        guard !turnWarmths.isEmpty else { return warmth }
        let weights = (1...turnWarmths.count).map { Double($0) }
        let sumW = weights.reduce(0, +)
        let weighted = zip(turnWarmths, weights).map { $0 * $1 }.reduce(0, +)
        return sumW > 0 ? (weighted / sumW) : warmth
    }

    /// Final profile for LLM and 10s commit when conversationTurn == 15.
    func buildSoulProfile() -> SoulProfile {
        SoulProfile(
            warmth: warmth,
            energy: energy,
            chaos: chaos,
            conversationTurn: conversationTurn,
            sessionSummary: sessionTranscriptSnippets.joined(separator: " | "),
            draftEnergy: profileDraft.energy,
            draftIntimacy: profileDraft.intimacy,
            draftColorId: profileDraft.colorId,
            draftMood: profileDraft.currentMood,
            draftOpenness: profileDraft.openness,
            draftCommunicationStyle: profileDraft.communicationStyle,
            draftShellType: profileDraft.shellType,
            draftPersonalityBase: profileDraft.personalityBase,
            shadowSummary: shadowThoughtProcesses.isEmpty ? nil : shadowThoughtProcesses.suffix(10).joined(separator: " | ")
        )
    }

    // MARK: - Private analysis

    private func computeWarmthTarget(inputText: String) -> Double {
        sentimentTagger.string = inputText
        let (tag, _) = sentimentTagger.tag(
            at: inputText.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )
        let score = Double(tag?.rawValue ?? "0") ?? 0
        if score > 0.2 { return 1.0 }
        if score < -0.2 { return 0.0 }
        return warmth
    }

    /// Energy = (LengthFactor * 0.4) + (AudioAmplitudeFactor * 0.6). Amplitude from normalizedPower (0...1).
    private func computeEnergyTarget(inputText: String, audioAmplitude: Float = 0) -> Double {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let len = trimmed.count
        let hasExclamation = trimmed.contains("!")
        let hasEllipsis = trimmed.contains("...") || trimmed.contains("…")
        let isShort = len < 30
        let isLong = len > 80
        var lengthFactor: Double = 0.5
        if hasExclamation || isShort { lengthFactor = 1.0 }
        else if hasEllipsis || isLong { lengthFactor = 0.0 }

        let amplitudeFactor = min(1.0, max(0, Double(audioAmplitude)))
        let target = (lengthFactor * 0.4) + (amplitudeFactor * 0.6)
        return clamp(target, 0, 1)
    }

    private func computeChaosTarget(inputText: String) -> Double {
        let lower = inputText.lowercased()
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        var delta: Double = 0
        for w in words {
            if Self.chaosIncreaseKeywords.contains(w) { delta += 0.08 }
            if Self.chaosDecreaseKeywords.contains(w) { delta -= 0.08 }
        }
        let target = chaos + delta
        return clamp(target, 0, 1)
    }

    private func lerp(current: Double, target: Double, factor: Double) -> Double {
        current + (target - current) * factor
    }

    private func clamp(_ value: Double, _ lo: Double, _ hi: Double) -> Double {
        min(hi, max(lo, value))
    }
}
