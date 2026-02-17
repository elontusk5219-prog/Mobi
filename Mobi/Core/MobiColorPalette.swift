//
//  MobiColorPalette.swift
//  Mobi
//
//  Preset Morandi-style palette for soul color. METADATA must use palette_id or palette hex only.
//

import Combine
import SwiftUI

/// 5 Morandi colors for soul casting. Used for METADATA color normalization and Fallback.
enum MobiColorPalette: String, CaseIterable {
    case dustyRose   = "dusty_rose"
    case sage        = "sage"
    case oat         = "oat"
    case slateBlue   = "slate_blue"
    case clay        = "clay"

    var hex: String {
        switch self {
        case .dustyRose: return "#C4A494"
        case .sage:      return "#9CAF88"
        case .oat:      return "#D4C5B0"
        case .slateBlue: return "#7B8FA1"
        case .clay:     return "#B8957A"
        }
    }

    var swiftUIColor: Color {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard s.count == 6, let u = UInt64(s, radix: 16) else { return Color(red: 0.83, green: 0.77, blue: 0.69) }
        return Color(
            red: Double((u >> 16) & 0xFF) / 255,
            green: Double((u >> 8) & 0xFF) / 255,
            blue: Double(u & 0xFF) / 255
        )
    }

    /// Default (fallback) palette entry when API fails or no choice.
    static var fallback: MobiColorPalette { .oat }

    /// Resolve palette id or hex string to hex. If invalid, returns fallback hex.
    static func resolveToHex(_ colorOrId: String?) -> String? {
        guard let s = colorOrId?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if let p = MobiColorPalette(rawValue: s) { return p.hex }
        if s.hasPrefix("#"), s.count == 7 { return nearestPaletteHex(to: s) }
        return nil
    }

    /// Resolve to a palette id (for storage/API). If hex, map to nearest palette id.
    static func resolveToPaletteId(_ colorOrId: String?) -> String? {
        guard let s = colorOrId?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if MobiColorPalette(rawValue: s) != nil { return s }
        if s.hasPrefix("#"), let hex = nearestPaletteHex(to: s), let p = allByHex[hex] { return p.rawValue }
        return nil
    }

    /// Given arbitrary hex, return hex of nearest palette color (for normalization).
    private static func nearestPaletteHex(to hex: String) -> String? {
        let list = MobiColorPalette.allCases.map { $0.hex }
        guard let (r, g, b) = parseHex(hex) else { return fallback.hex }
        var best: (String, Double) = (fallback.hex, 1e9)
        for h in list {
            guard let (r2, g2, b2) = parseHex(h) else { continue }
            let d = (r - r2) * (r - r2) + (g - g2) * (g - g2) + (b - b2) * (b - b2)
            if d < best.1 { best = (h, d) }
        }
        return best.0
    }

    private static func parseHex(_ hex: String) -> (Double, Double, Double)? {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard s.count == 6, let u = UInt64(s, radix: 16) else { return nil }
        return (
            Double((u >> 16) & 0xFF) / 255,
            Double((u >> 8) & 0xFF) / 255,
            Double(u & 0xFF) / 255
        )
    }

    private static var allByHex: [String: MobiColorPalette] {
        Dictionary(uniqueKeysWithValues: MobiColorPalette.allCases.map { ($0.hex, $0) })
    }

    /// All valid palette ids for prompt constraint.
    static var allIds: [String] { allCases.map { $0.rawValue } }
}
