//
//  HeartbeatEngine.swift
//  Mobi
//
//  Sensory Progression: when progress > 0.8, play a background heartbeat that increases in tempo.
//

import Foundation
import CoreHaptics

final class HeartbeatEngine {
    static let shared = HeartbeatEngine()

    private var engine: CHHapticEngine?
    private var timer: Timer?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.stoppedHandler = { [weak self] _ in
                DispatchQueue.main.async { try? self?.engine?.start() }
            }
        } catch {
            print("[HeartbeatEngine] Failed to start: \(error)")
        }
    }

    /// Progress 0.0–1.0. When > 0.8, plays heartbeat; tempo increases from ~60 BPM to ~120 BPM.
    func updateProgress(_ progress: Double) {
        let p = min(1, max(0, progress))
        guard p > 0.8 else {
            stop()
            return
        }
        let interval = beatInterval(for: p)
        DispatchQueue.main.async { [weak self] in
            self?.startOrUpdateTimer(interval: interval)
        }
    }

    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = nil
        }
    }

    private func beatInterval(for progress: Double) -> TimeInterval {
        let t = (progress - 0.8) / 0.2
        return 1.0 - t * 0.5
    }

    private func startOrUpdateTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playOneBeat()
        }
        playOneBeat()
    }

    private func playOneBeat() {
        guard let engine = engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let e1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let e2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
        do {
            let pattern = try CHHapticPattern(events: [e1, e2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Ignore; engine may be stopped
        }
    }
}
