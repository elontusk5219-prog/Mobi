//
//  ComplementaryEngine.swift
//  Mobi
//
//  Complementary logic (补缺引擎): V_Seed = P_Balance − V_User.
//  Drives Mobi orb appearance from user psyche (warmth, energy, structure).
//

import Foundation
import SwiftUI

// MARK: - Double Clamped

private extension Double {
    func clamped(to range: ClosedRange<Double> = 0...1) -> Double {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

// MARK: - SoulVector (T/E/S for resonant seed)

struct SoulVector {
    var warmth: Double
    var energy: Double
    var structure: Double

    /// V_Seed = 1.0 - V_User with SoulResonator perturbation (DeltaSurprise).
    static func generateResonantSeed(from user: SoulVector, deltaSurprise: Double = 0) -> SoulVector {
        let baseWarmth = 1.0 - user.warmth
        let baseEnergy = 1.0 - user.energy
        let baseStructure = 1.0 - user.structure
        let range = 0.08 * (1.0 + deltaSurprise)
        let offset = { Double.random(in: -range...range) }
        return SoulVector(
            warmth: (baseWarmth + offset()).clamped(),
            energy: (baseEnergy + offset()).clamped(),
            structure: (baseStructure + offset()).clamped()
        )
    }
}

// MARK: - MobiSeed (output for NebulaSoulView)

struct MobiSeed {
    let warmth: Double
    let energy: Double
    let structure: Double
    let themeColor: Color
    /// Physical density 0...1 (affects post-Genesis motion; low when user says tired/heavy).
    let density: Double
}

// MARK: - ComplementaryEngine

final class ComplementaryEngine {
    private let targetBalance: Double = 1.0

    /// Complement of user warmth for theme color (cool when user warm, warm when user cool).
    private func colorFromWarmth(_ amount: Double) -> Color {
        let a = amount.clamped()
        return Color(
            red: (1 - a) * 0.2 + a * 1.0,
            green: (1 - a) * 0.4 + a * 0.5,
            blue: (1 - a) * 1.0 + a * 0.1
        )
    }

    /// Inverted color from user warmth (1.0 − warmth → theme).
    private func calculateInvertedColor(warmth: Double) -> Color {
        colorFromWarmth(1.0 - warmth)
    }

    /// Generate Mobi seed from user psyche. SoulResonator injects DeltaSurprise and density.
    func generateMobiSeed(from user: UserPsycheModel, entropy: Double = 0, lastInputText: String = "") -> MobiSeed {
        let userVector = SoulVector(
            warmth: user.warmth,
            energy: user.energy,
            structure: 1.0 - user.chaos
        )
        let localEntropy = lastInputText.isEmpty ? 0 : SoulResonator.entropy(from: lastInputText)
        let deltaSurprise = SoulResonator.deltaSurprise(localEntropy: localEntropy, externalEntropy: entropy)
        let seed = SoulVector.generateResonantSeed(from: userVector, deltaSurprise: deltaSurprise)
        let themeColor = colorFromWarmth(1.0 - user.weightedAverageWarmth)
        let density = SoulResonator.density(warmth: user.warmth, energy: user.energy, text: lastInputText)
        return MobiSeed(
            warmth: seed.warmth,
            energy: seed.energy,
            structure: seed.structure,
            themeColor: themeColor,
            density: density
        )
    }
}
