//
//  ParallaxMotionService.swift
//  Mobi
//
//  CoreMotion gyroscope-driven parallax offset for 2.5D Room depth.
//

import Foundation
import CoreMotion
import Combine
import SwiftUI

@MainActor
final class ParallaxMotionService: ObservableObject {
    static let shared = ParallaxMotionService()

    @Published private(set) var parallaxOffset: CGSize = .zero

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let multiplier: CGFloat = 25
    private let smoothing: Double = 0.15

    private var lastRoll: Double = 0
    private var lastPitch: Double = 0

    private init() {
        queue.maxConcurrentOperationCount = 1
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            let m = self.multiplier
            Task { @MainActor in
                self.lastRoll = self.lastRoll * (1 - self.smoothing) + roll * self.smoothing
                self.lastPitch = self.lastPitch * (1 - self.smoothing) + pitch * self.smoothing
                self.parallaxOffset = CGSize(width: CGFloat(self.lastRoll) * m, height: CGFloat(self.lastPitch) * m)
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        parallaxOffset = .zero
    }
}
