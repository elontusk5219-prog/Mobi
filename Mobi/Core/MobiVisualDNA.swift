//
//  MobiVisualDNA.swift
//  Mobi
//
//  Visual, physical, and material parameters from SoulProfile (LLM or Fallback).
//

import SwiftUI

struct MobiVisualDNA: Codable {
    // Visual
    var eyeSpacing: Double      // 0.0-1.0
    var eyeScale: Double        // 0.5-1.5
    var fuzziness: Double       // 0.0-1.0
    var blushOpacity: Double   // 0.0-1.0
    var eyeShape: String       // round | droopy | line | sharp | gentle | sleepy | dot | star | heart | diamond | crescent | wide | narrow | upturned | curious | sparkle
    var earType: String?       // rabbit | hamster | bear | ... | none; nil = hamster
    var bodyForm: String?       // round | rounded_square | ... | blob; nil = round
    var bodyColorHex: String
    var personalitySlotType: String?  // pattern | pendant | sticker | energy_bar | collection; nil = sticker
    var mouthShape: String?     // smile | grin | line | calm | gentle; 性格映射，child/adult 时渲染

    // Physics
    var movementResponse: Double  // 0.1(slow)-0.9(snappy), Energy
    var bounciness: Double       // 0.0(clay)-0.8(jelly), Chaos
    var softness: Double         // 0.0(rock)-1.0(stretchy), Warmth
    var bodyShapeFactor: Double  // 0.0(round)-1.0(trapezoid), Intimacy

    // Color & Material (Art Director)
    var paletteId: String   // dusty_rose | sunshine_citrus | deep_ocean | electric_neon | natural_clay
    var materialId: String  // fuzzy_felt | gummy_jelly | matte_clay | smooth_plastic

    enum CodingKeys: String, CodingKey {
        case eyeSpacing = "eye_spacing"
        case eyeScale = "eye_scale"
        case fuzziness
        case blushOpacity = "blush_opacity"
        case eyeShape = "eye_shape"
        case earType = "ear_type"
        case bodyForm = "body_form"
        case bodyColorHex = "body_color_hex"
        case personalitySlotType = "personality_slot_type"
        case mouthShape = "mouth_shape"
        case movementResponse = "movement_response"
        case bounciness
        case softness
        case bodyShapeFactor = "body_shape_factor"
        case paletteId = "palette_id"
        case materialId = "material_id"
    }

    static var `default`: MobiVisualDNA {
        MobiVisualDNA(
            eyeSpacing: 0.5,
            eyeScale: 1.0,
            fuzziness: 0.1,
            blushOpacity: 0.3,
            eyeShape: "round",
            earType: "hamster",
            bodyForm: "round",
            bodyColorHex: "D4C5B0",
            personalitySlotType: "sticker",
            mouthShape: "gentle",
            movementResponse: 0.5,
            bounciness: 0.4,
            softness: 0.5,
            bodyShapeFactor: 0.2,
            paletteId: "natural_clay",
            materialId: "matte_clay"
        )
    }
}
