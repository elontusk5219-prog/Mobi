//
//  SoulResonator.swift
//  Mobi
//
//  Dynamic resonance: DeltaSurprise, Entropy, and physical density for MobiSeed.
//

import Foundation

/// Computes entropy (vocabulary richness), delta surprise, and density for the complementary seed.
enum SoulResonator {
    /// Entropy 0...1 from vocabulary richness (unique words / word count) of the given text.
    static func entropy(from text: String) -> Double {
        let lower = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else { return 0 }
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        guard !words.isEmpty else { return 0 }
        let unique = Set(words).count
        let ratio = Double(unique) / Double(words.count)
        return min(1, max(0, ratio))
    }

    /// Delta surprise for seed perturbation: combines local entropy with optional external entropy.
    static func deltaSurprise(localEntropy: Double, externalEntropy: Double = 0) -> Double {
        let combined = (localEntropy * 0.6 + externalEntropy * 0.4)
        return min(1, max(0, combined))
    }

    /// Physical density 0...1 from energy, warmth, and optional text cues (e.g. "tired"/"heavy" → low).
    static func density(warmth: Double, energy: Double, text: String = "") -> Double {
        var d = 0.25 + 0.35 * min(1, max(0, energy)) + 0.35 * min(1, max(0, warmth))
        let lower = text.lowercased()
        if lower.contains("tired") || lower.contains("heavy") {
            d = min(d, 0.25)
        }
        return min(1, max(0, d))
    }
}
