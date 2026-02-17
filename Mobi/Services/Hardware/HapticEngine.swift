//
//  HapticEngine.swift
//  Mobi
//

import Foundation
import UIKit

final class HapticEngine {
    static let shared = HapticEngine()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)

    func playLight() {
        lightGenerator.impactOccurred()
    }
    func playMedium() {
        mediumGenerator.impactOccurred()
    }
    func playHeavy() {
        heavyGenerator.impactOccurred()
    }
    func playSoft() {
        softGenerator.impactOccurred()
    }
}
