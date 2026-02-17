//
//  PersonalityToDNAMapper.swift
//  Mobi
//
//  根据 SoulProfile 推导 MobiVisualDNA，供 API 失败时本地兜底。
//  映射规则见 docs/PhaseIII-资产与人格映射表.md
//

import Foundation
import SwiftUI

enum PersonalityToDNAMapper {
    /// 从 SoulProfile 推导 MobiVisualDNA。API 失败时替代 MobiVisualDNA.default。
    static func map(from profile: SoulProfile) -> MobiVisualDNA {
        let shell = (profile.draftShellType ?? "").lowercased()
        let base = (profile.draftPersonalityBase ?? "").lowercased()
        let mood = (profile.draftMood ?? "").lowercased()
        let colorId = profile.draftColorId ?? "natural_clay"
        let intimacy = Double(profile.draftIntimacy ?? 50) / 100
        let openness = (profile.draftOpenness ?? "").lowercased()

        let materialId = materialId(shell: shell, personalityBase: base)
        let paletteId = paletteId(colorId: colorId, base: base, mood: mood)
        let eyeShape = eyeShape(base: base, mood: mood)
        let earType = earType(base: base, shell: shell, mood: mood)
        let bodyForm = bodyForm(base: base, shell: shell)
        let personalitySlotType = personalitySlotType(base: base, shell: shell)
        let mouthShape = mouthShapeFromBase(base)

        var (bounciness, movementResponse, softness) = physics(base: base, shell: shell)
        let (eyeScale, eyeSpacing, blushOpacity, fuzziness) = eyeDetails(openness: openness, intimacy: intimacy, base: base, shell: shell)

        if shell == "armored" {
            movementResponse = max(0.1, movementResponse - 0.1)
            softness = max(0, softness - 0.2)
        } else if shell == "soft" {
            softness = min(1.0, softness + 0.2)
        } else if shell == "resilient" {
            bounciness = min(0.8, bounciness + 0.1)
        }

        let bodyColorHex = hexFromPalette(paletteId)

        return MobiVisualDNA(
            eyeSpacing: eyeSpacing,
            eyeScale: eyeScale,
            fuzziness: fuzziness,
            blushOpacity: blushOpacity,
            eyeShape: eyeShape,
            earType: earType,
            bodyForm: bodyForm,
            bodyColorHex: bodyColorHex,
            personalitySlotType: personalitySlotType,
            mouthShape: mouthShape,
            movementResponse: movementResponse,
            bounciness: bounciness,
            softness: softness,
            bodyShapeFactor: intimacy > 0.6 ? 0.3 : 0.15,
            paletteId: paletteId,
            materialId: materialId
        )
    }

    private static func materialId(shell: String, personalityBase: String) -> String {
        if personalityBase == "quiet" { return "matte_clay" }
        if personalityBase == "healing" { return "fuzzy_felt" }
        if personalityBase == "playful" { return "gummy_jelly" }
        if shell == "armored" { return "matte_clay" }
        if shell == "soft" { return "fuzzy_felt" }
        if shell == "resilient" { return personalityBase == "warm" ? "smooth_plastic" : "gummy_jelly" }
        return "matte_clay"
    }

    private static func paletteId(colorId: String, base: String, mood: String) -> String {
        if !colorId.isEmpty { return colorId }
        if base == "warm" || mood == "warm" { return "dusty_rose" }
        if mood.contains("playful") || base == "playful" { return "sunshine_citrus" }
        if mood == "defensive" || mood == "cold" { return "deep_ocean" }
        if mood == "aggressive" { return "electric_neon" }
        return "natural_clay"
    }

    private static func eyeShape(base: String, mood: String) -> String {
        if mood == "tired" { return "sleepy" }
        if mood == "defensive" || mood == "aggressive" { return "sharp" }
        if base == "quiet" { return "droopy" }
        if base == "healing" || base == "warm" { return "gentle" }
        if base == "playful" { return "round" }
        return "round"
    }

    private static func earType(base: String, shell: String, mood: String) -> String {
        if shell == "armored" && mood == "defensive" { return "cat" }
        if shell == "armored" { return "none" }
        if base == "healing" { return "rabbit" }
        if base == "playful" { return "rabbit" }
        if base == "warm" { return "bear" }
        if base == "quiet" { return "hamster" }
        return "hamster"
    }

    private static func bodyForm(base: String, shell: String) -> String {
        if base == "quiet" || shell == "armored" { return "rounded_square" }
        if base == "healing" || base == "playful" { return "round" }
        if base == "warm" { return "triangular" }
        return "round"
    }

    private static func mouthShapeFromBase(_ base: String) -> String {
        switch base {
        case "healing": return "smile"
        case "playful": return "grin"
        case "quiet": return "line"
        case "resilient": return "calm"
        case "warm": return "gentle"
        default: return "gentle"
        }
    }

    private static func personalitySlotType(base: String, shell: String) -> String {
        if base == "healing" { return "pattern" }
        if base == "playful" { return "pendant" }
        if shell == "armored" { return "energy_bar" }
        if base == "warm" { return "collection" }
        return "sticker"
    }

    private static func physics(base: String, shell: String) -> (bounciness: Double, movementResponse: Double, softness: Double) {
        switch base {
        case "healing": return (0.35, 0.4, 0.8)
        case "playful": return (0.7, 0.75, 0.6)
        case "quiet": return (0.25, 0.3, 0.5)
        case "resilient": return (0.6, 0.6, 0.55)
        case "warm": return (0.45, 0.5, 0.7)
        default: return (0.4, 0.5, 0.5)
        }
    }

    private static func eyeDetails(openness: String, intimacy: Double, base: String, shell: String) -> (eyeScale: Double, eyeSpacing: Double, blushOpacity: Double, fuzziness: Double) {
        var eyeScale = 1.0
        var eyeSpacing = 0.5
        var blushOpacity = 0.3
        var fuzziness = 0.1

        if openness == "high" {
            eyeScale = 1.1
            eyeSpacing = 0.5
            blushOpacity = 0.45
            fuzziness = 0.25
        } else if openness == "low" {
            eyeScale = 0.9
            eyeSpacing = 0.6
            blushOpacity = 0.25
            fuzziness = 0.15
        }
        if intimacy > 0.6 {
            eyeScale = max(eyeScale, 1.05)
            blushOpacity = max(blushOpacity, 0.5)
        }
        if base == "healing" || shell == "soft" {
            blushOpacity = 0.5
            fuzziness = 0.3
        }
        if base == "quiet" || shell == "armored" {
            blushOpacity = 0.15
            fuzziness = 0.08
        }
        return (eyeScale, eyeSpacing, blushOpacity, fuzziness)
    }

    private static func hexFromPalette(_ paletteId: String) -> String {
        switch paletteId {
        case "dusty_rose": return "D4A5A5"
        case "sunshine_citrus": return "F5D68A"
        case "deep_ocean": return "7B9EB0"
        case "electric_neon": return "B8A9D4"
        default: return "D4C5B0"
        }
    }
}
