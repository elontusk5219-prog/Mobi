//
//  SoulMetadataParser.swift
//  Mobi
//
//  Parses [METADATA: ...] and METADATA_UPDATE: {...} from LLM reply;
//  strips blocks so user/TTS never see JSON; returns draft update and transition trigger.
//

import Foundation

// MARK: - Draft Update (from METADATA_UPDATE, stealth)

struct MetadataDraftUpdate {
    var energyTag: String?
    var intimacyTag: String?
    var colorId: String?
    /// Keywords user evoked (e.g. tired, coffee, sea) — passed to Shader for subtle tremor. Parsed from "sea/fire/soft" or array.
    var vibeKeywords: [String]?
    /// Shadow Analysis: brief analyst note (e.g. "User said X, indicates Y").
    var thoughtProcess: String?
    var currentMood: String?
    var energyLevel: String?
    var openness: String?
    var communicationStyle: String?
    /// Mobi shell type: Armored / Soft / Resilient (from user aggression/defense).
    var shellType: String?
    /// Mobi personality base: Healing / Playful / Quiet / Resilient / Warm (complementary or resonant).
    var personalityBase: String?
}

// MARK: - Soul Metadata (15-Turn Profiler, legacy [METADATA: ...])

struct SoulMetadata {
    var turn: Int
    var stage: String
    var trait: String
    /// Palette id (e.g. dusty_rose) or hex. Resolve with MobiColorPalette.resolveToHex for display.
    var color: String
    var erosion: Double
    /// Final personality color (turns 13+); palette id or hex. When set, frontend converges to this palette.
    var finalSoulColor: String?
    /// Cold-reading: "low" | "high" from energy binary (累 vs 刚开始).
    var energyTag: String?
    /// Cold-reading: "low" | "high" from distance binary (保持距离 vs 靠近).
    var intimacyTag: String?
}

// MARK: - Parser

enum SoulMetadataParser {
    private static let metadataPattern = #"\[METADATA:\s*(\{[^]]+\})\]"#
    /// Single-line JSON object after METADATA_UPDATE: (no nested braces in value).
    private static let metadataUpdatePattern = #"METADATA_UPDATE:\s*(\{[^}]+\})"#

    /// One-pass: strip all METADATA_UPDATE blocks (merge, last wins), then strip optional [METADATA: ...]. Returns clean text, draft update, transition flag, and legacy metadata.
    static func parseAndStripAll(text: String, currentTurn: Int) -> (strippedText: String, draftUpdate: MetadataDraftUpdate?, triggerGenesisComplete: Bool, legacyMetadata: SoulMetadata?) {
        var mergedDraft: MetadataDraftUpdate?
        var work = text

        if let regex = try? NSRegularExpression(pattern: SoulMetadataParser.metadataUpdatePattern) {
            let range = NSRange(work.startIndex..., in: work)
            let matches = regex.matches(in: work, range: range)
            for match in matches {
                guard match.numberOfRanges > 1,
                      let jsonRange = Range(match.range(at: 1), in: work) else { continue }
                let jsonString = String(work[jsonRange])
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var next = mergedDraft ?? MetadataDraftUpdate()
                    if let v = json["energy_tag"] as? String { next.energyTag = v }
                    if let v = json["intimacy_tag"] as? String { next.intimacyTag = v }
                    if let v = json["color_id"] as? String { next.colorId = v }
                    if let arr = json["vibe_keywords"] as? [String] {
                        next.vibeKeywords = arr
                    } else if let s = json["vibe_keywords"] as? String, !s.isEmpty {
                        next.vibeKeywords = s.split(separator: "/").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    }
                    if let v = json["thought_process"] as? String { next.thoughtProcess = v }
                    if let v = json["current_mood"] as? String { next.currentMood = v }
                    if let v = json["energy_level"] as? String { next.energyLevel = v }
                    if let v = json["openness"] as? String { next.openness = v }
                    if let v = json["communication_style"] as? String { next.communicationStyle = v }
                    if let v = json["shell_type"] as? String { next.shellType = v }
                    if let v = json["personality_base"] as? String { next.personalityBase = v }
                    mergedDraft = next
                }
            }
            work = regex.stringByReplacingMatches(in: work, options: [], range: range, withTemplate: "")
            work = work.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let (strippedText, legacyMetadata) = parseAndStripMetadata(text: work)
        let triggerGenesisComplete = (currentTurn == 15)
        return (strippedText, mergedDraft, triggerGenesisComplete, legacyMetadata)
    }

    /// Strips first [METADATA: {...}] and returns remaining text + parsed metadata if valid.
    static func parseAndStripMetadata(text: String) -> (strippedText: String, metadata: SoulMetadata?) {
        guard let regex = try? NSRegularExpression(pattern: metadataPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return (text, nil)
        }

        let fullRange = Range(match.range, in: text)!
        let jsonRange = Range(match.range(at: 1), in: text)!
        let jsonString = String(text[jsonRange])

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let metadata = SoulMetadata(from: json) else {
            return (text, nil)
        }

        let strippedText = text.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return (strippedText, metadata)
    }
}

// MARK: - SoulMetadata from JSON

private extension SoulMetadata {
    init?(from json: [String: Any]) {
        guard let turn = json["turn"] as? Int,
              let stage = json["stage"] as? String,
              let trait = json["trait"] as? String,
              let color = json["color"] as? String,
              let erosion = (json["erosion"] as? NSNumber)?.doubleValue ?? (json["erosion"] as? Double) else {
            return nil
        }
        self.turn = turn
        self.stage = stage
        self.trait = trait
        self.color = color
        self.erosion = erosion
        self.finalSoulColor = json["final_soul_color"] as? String
        self.energyTag = json["energy_tag"] as? String
        self.intimacyTag = json["intimacy_tag"] as? String
    }
}
