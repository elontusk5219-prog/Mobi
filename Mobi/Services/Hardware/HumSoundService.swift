//
//  HumSoundService.swift
//  Mobi
//
//  Looping low-frequency "Hum" for Stage 2 haptic lure. No-op if no asset is bundled.
//

import Foundation
import AVFoundation

final class HumSoundService {
    static let shared = HumSoundService()

    private var player: AVAudioPlayer?

    private init() {}

    func playIfAvailable() {
        // TODO: Bundle a hum.mp3 and load with AVAudioPlayer, set numberOfLoops = -1, play()
        // For now no-op so Stage 2 only uses haptic.
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
