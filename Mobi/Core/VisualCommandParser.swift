//
//  VisualCommandParser.swift
//  Mobi
//
//  Parses [v: param=value] tags from LLM response; strips tag and returns clean text for TTS.
//

import SwiftUI

// MARK: - Visual Command (Hidden Tag protocol)

struct VisualCommand {
    enum FluidColor: String, CaseIterable {
        case orange
        case blue
        case red
        case green
        case purple
        case white

        var swiftUIColor: Color {
            switch self {
            case .orange: return Color(red: 1.0, green: 0.6, blue: 0.4)
            case .blue: return Color(red: 0.3, green: 0.4, blue: 0.9)
            case .red: return Color(red: 0.9, green: 0.3, blue: 0.3)
            case .green: return Color(red: 0.4, green: 0.9, blue: 0.5)
            case .purple: return Color(red: 0.5, green: 0.3, blue: 0.8)
            case .white: return Color(red: 0.95, green: 0.95, blue: 0.97)
            }
        }

        /// Map warmth (0–1) + turn to FluidColor for user-input-driven Orb. Each turn adds slight hue shift.
        static func fromWarmthAndTurn(warmth: Double, turn: Int) -> FluidColor {
            let w = min(1, max(0, warmth))
            let r = (1 - w) * 0.2 + w * 1.0
            let g = (1 - w) * 0.4 + w * 0.5
            let b = (1 - w) * 1.0 + w * 0.1
            let shift = Double(turn % 6) * 0.08
            let c = (min(1, r + shift), min(1, g + shift * 0.5), min(1, b - shift))
            let list: [(FluidColor, (Double, Double, Double))] = [
                (.orange, (1.0, 0.6, 0.4)),
                (.blue, (0.3, 0.4, 0.9)),
                (.red, (0.9, 0.3, 0.3)),
                (.green, (0.4, 0.9, 0.5)),
                (.purple, (0.5, 0.3, 0.8)),
                (.white, (0.95, 0.95, 0.97))
            ]
            func dist(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
                (a.0 - b.0) * (a.0 - b.0) + (a.1 - b.1) * (a.1 - b.1) + (a.2 - b.2) * (a.2 - b.2)
            }
            return list.min(by: { dist($0.1, c) < dist($1.1, c) })?.0 ?? .blue
        }

        /// Map METADATA hex (e.g. "#4682B4") to closest FluidColor for color injection.
        static func from(hex: String) -> FluidColor? {
            let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            guard s.count == 6, let u = UInt64(s, radix: 16) else { return nil }
            let r = Double((u >> 16) & 0xFF) / 255
            let g = Double((u >> 8) & 0xFF) / 255
            let b = Double(u & 0xFF) / 255
            let c = (r, g, b)
            let list: [(FluidColor, (Double, Double, Double))] = [
                (.orange, (1.0, 0.6, 0.4)),
                (.blue, (0.3, 0.4, 0.9)),
                (.red, (0.9, 0.3, 0.3)),
                (.green, (0.4, 0.9, 0.5)),
                (.purple, (0.5, 0.3, 0.8)),
                (.white, (0.95, 0.95, 0.97))
            ]
            func dist(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
                (a.0 - b.0) * (a.0 - b.0) + (a.1 - b.1) * (a.1 - b.1) + (a.2 - b.2) * (a.2 - b.2)
            }
            return list.min(by: { dist($0.1, c) < dist($1.1, c) })?.0
        }
    }

    enum Shape: String, CaseIterable {
        case round   // fluid / soft
        case square  // sharp / crystalline / high-structure
        case liquid  // same as round
        case sharp   // same as square
    }

    enum Mood: String, CaseIterable {
        case calm    // slow motion
        case excited // fast pulse
        case chaos   // high turbulence
    }

    enum Speed: String, CaseIterable {
        case slow
        case fast
    }

    var color: FluidColor?
    var shape: Shape?
    var mood: Mood?
    var speed: Speed?
}

// MARK: - Parser

enum VisualCommandParser {
    private static let tagPattern = #"\[v:\s*([^\]]*?)\]"#

    /// Finds first `[v: ...]` tag, parses param=value pairs, returns text without the tag and optional command.
    static func parseAndStripVisualTags(text: String) -> (cleanText: String, command: VisualCommand?) {
        guard let regex = try? NSRegularExpression(pattern: tagPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return (text, nil)
        }

        let fullRange = Range(match.range, in: text)!
        let tagContentRange = Range(match.range(at: 1), in: text)!
        let tagContent = String(text[tagContentRange])

        var command = VisualCommand()
        for part in tagContent.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            let pair = part.split(separator: "=").map { $0.trimmingCharacters(in: .whitespaces) }
            guard pair.count == 2 else { continue }
            let key = pair[0].lowercased()
            let value = pair[1].lowercased()

            switch key {
            case "color":
                if let c = VisualCommand.FluidColor(rawValue: value) { command.color = c }
            case "shape":
                if let s = VisualCommand.Shape(rawValue: value) { command.shape = s }
            case "mood":
                if let m = VisualCommand.Mood(rawValue: value) { command.mood = m }
            case "speed":
                if let s = VisualCommand.Speed(rawValue: value) { command.speed = s }
            default:
                break
            }
        }

        let hasAnyParam = command.color != nil || command.shape != nil || command.mood != nil || command.speed != nil
        let cleanText = text.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return (cleanText, hasAnyParam ? command : nil)
    }

    /// Alias for TTS pipeline: strip tag and return clean text + optional command.
    static func parseAndStrip(text: String) -> (cleanText: String, command: VisualCommand?) {
        parseAndStripVisualTags(text: text)
    }
}
