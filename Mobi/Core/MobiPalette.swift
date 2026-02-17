//
//  MobiPalette.swift
//  Mobi
//
//  Art Director palettes for DNA body gradient. palette_id → [Color].
//

import SwiftUI

enum MobiPalette {
    case dustyRose
    case sunshineCitrus
    case deepOcean
    case electricNeon
    case naturalClay

    /// Map palette_id string (snake_case) to palette case.
    static func from(id: String) -> MobiPalette {
        switch id.lowercased() {
        case "dusty_rose": return .dustyRose
        case "sunshine_citrus": return .sunshineCitrus
        case "deep_ocean": return .deepOcean
        case "electric_neon": return .electricNeon
        case "natural_clay": return .naturalClay
        default: return .naturalClay
        }
    }

    /// Returns [lighter, darker] for RadialGradient body fill.
    var colors: [Color] {
        switch self {
        case .dustyRose:      return [Color.hex("E8D0D0"), Color.hex("F7E6E6")]
        case .sunshineCitrus: return [Color.hex("FF8C00"), Color.hex("FFD93D")]
        case .deepOcean:      return [Color.hex("2C5F8D"), Color.hex("5B9BD5")]
        case .electricNeon:   return [Color.hex("FF1493"), Color.hex("00FFFF")]
        case .naturalClay:   return [Color.hex("B8957A"), Color.hex("D4C5B0")]
        }
    }
}

// MARK: - Color hex helper
extension Color {
    /// Parse hex string (with or without #) to Color.
    static func hex(_ hex: String) -> Color {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let u = UInt64(s, radix: 16) ?? 0
        return Color(
            red: Double((u >> 16) & 0xFF) / 255,
            green: Double((u >> 8) & 0xFF) / 255,
            blue: Double(u & 0xFF) / 255
        )
    }
}
