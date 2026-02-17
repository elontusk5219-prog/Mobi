//
//  SnapHapticService.swift
//  Mobi
//
//  The Sacred Snap: Continuous (flow) then Transient (collapse) via Core Haptics.
//

import Foundation
import CoreHaptics

final class SnapHapticService {
    static let shared = SnapHapticService()

    private var engine: CHHapticEngine?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.stoppedHandler = { [weak self] _ in
                DispatchQueue.main.async { try? self?.engine?.start() }
            }
        } catch {
            print("[SnapHaptic] Engine failed: \(error)")
        }
    }

    /// Play flow (continuous) then collapse (transient). Call when The Snap starts.
    func playSnapSequence() {
        guard let engine = engine else { return }
        let flowDuration = 0.25
        let flowIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35)
        let flowSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
        let flow = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [flowIntensity, flowSharpness],
            relativeTime: 0,
            duration: flowDuration
        )
        let transIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let transSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
        let trans = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [transIntensity, transSharpness],
            relativeTime: flowDuration
        )
        do {
            let pattern = try CHHapticPattern(events: [flow, trans], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("[SnapHaptic] Pattern failed: \(error)")
        }
    }
}
