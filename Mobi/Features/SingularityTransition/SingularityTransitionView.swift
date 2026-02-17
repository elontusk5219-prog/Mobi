//
//  SingularityTransitionView.swift
//  Mobi
//
//  Luminous Void: 10s transition (Ink-in-Milk). High-key white theme only.
//

import SwiftUI

// MARK: - Particle palette (high saturation, ink-like)

private let kIndigo = Color(red: 0.29, green: 0.22, blue: 0.49)
private let kCoral = Color(red: 0.98, green: 0.45, blue: 0.42)
private let kMint = Color(red: 0.40, green: 0.85, blue: 0.75)
private let kCyan = Color(red: 0.35, green: 0.78, blue: 0.92)
private let kParticleColors: [Color] = [kIndigo, kCoral, kMint, kCyan]

// MARK: - SingularityTransitionView

struct SingularityTransitionView: View {
    var onComplete: (() -> Void)?

    @State private var startTime: Date?
    @State private var haptic75Done = false
    @State private var mobiScale: CGFloat = 0
    @State private var hasStartedPhase3 = false
    @State private var hasCompleted = false
    @State private var audioEngine: ProceduralSoundEngine?
    @State private var hasTriggeredPhase2Audio = false
    @State private var hasTriggeredPhase3Audio = false

    private let particleCount = 50
    private let blurRadius: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            ZStack {
                // Background: Pure Off-White (Luminous Void)
                Color.hex("F5F5F7")
                    .ignoresSafeArea()

                TimelineView(.animation) { timeline in
                    let elapsed = startTime.map { timeline.date.timeIntervalSince($0) } ?? 0

                    ZStack {
                        // Phase 1 & 2: Particle canvas (50 fuzzy circles)
                        particleCanvas(size: size, center: center, elapsed: elapsed)
                            .scaleEffect(phase2Scale(elapsed))
                            .rotationEffect(.degrees(phase2Rotation(elapsed)))
                            .blendMode(.multiply)
                            .blur(radius: blurRadius)

                        // Phase 3: Emergence
                        if elapsed >= 7 {
                            phase3Content(size: size, center: center, elapsed: elapsed)
                        }

                        // White overlay: Flash in 6.8–7s, then fade out 7–7.8s (Luminous Void)
                        Color.white
                            .opacity(whiteOverlayOpacity(elapsed))
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                    .onChange(of: elapsed) { _, new in
                        handleHaptics(elapsed: new)
                        handlePhase3Start(elapsed: new)
                        handleAudioPhases(elapsed: new)
                        if new >= 10, !hasCompleted {
                            hasCompleted = true
                            onComplete?()
                        }
                    }
                }
            }
        }
        .onAppear {
            startTime = Date()
            let engine = ProceduralSoundEngine()
            audioEngine = engine
            engine.startEngine()
            engine.triggerPhase1_Nebula()
        }
    }

    // MARK: - Particle canvas (Phase 1 drift; Phase 2 same layer, scaled/rotated)

    private func particleCanvas(size: CGSize, center: CGPoint, elapsed: Double) -> some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                let color = kParticleColors[i % kParticleColors.count]
                let (x, y) = particlePosition(index: i, size: size, center: center, t: elapsed)
                let r = particleRadius(index: i)
                Circle()
                    .fill(color.opacity(0.85))
                    .frame(width: r * 2, height: r * 2)
                    .position(x: x, y: y)
            }
        }
    }

    private func particlePosition(index: Int, size: CGSize, center: CGPoint, t: Double) -> (CGFloat, CGFloat) {
        let i = Double(index)
        let spread: CGFloat = 0.42
        let baseX = center.x + CGFloat(sin(i * 0.7)) * size.width * spread * 0.5
        let baseY = center.y + CGFloat(cos(i * 0.5)) * size.height * spread * 0.5
        let drift = CGFloat(35)
        let dx = sin(t * 0.7 + i * 0.5) * drift
        let dy = cos(t * 0.5 + i * 0.3) * drift
        return (baseX + dx, baseY + dy)
    }

    private func particleRadius(index: Int) -> CGFloat {
        let seed = Double(index) * 0.13
        return CGFloat(28 + sin(seed) * 18 + cos(seed * 1.7) * 12)
    }

    private func phase2Scale(_ elapsed: Double) -> CGFloat {
        guard elapsed > 3 else { return 1 }
        if elapsed >= 7 { return 0.02 }
        let t = (elapsed - 3) / 4
        return 1 - (1 - 0.02) * t
    }

    private func phase2Rotation(_ elapsed: Double) -> Double {
        guard elapsed > 3, elapsed < 7 else { return elapsed >= 7 ? 360 : 0 }
        return 360 * (elapsed - 3) / 4
    }

    /// Flash (6.8s→7s): 0→1. Phase 3 (7s→7.8s): 1→0.
    private func whiteOverlayOpacity(_ elapsed: Double) -> Double {
        if elapsed < 6.8 { return 0 }
        if elapsed < 7 { return (elapsed - 6.8) / 0.2 }
        if elapsed < 7.8 { return 1 - (elapsed - 7) / 0.8 }
        return 0
    }

    // MARK: - Phase 3: Neumorphic Mobi + Ripple

    private func phase3Content(size: CGSize, center: CGPoint, elapsed: Double) -> some View {
        ZStack {
            // Ripple: gray ring expanding, opacity 0.2 -> 0
            let rippleProgress = min(1, (elapsed - 7) / 3)
            let rippleScale: CGFloat = 0.3 + rippleProgress * 1.2
            let rippleOpacity = 0.2 * (1 - rippleProgress)
            Circle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 120, height: 120)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)
                .position(center)

            // Mobi placeholder: Neumorphic circle (soft gray shadow + white inner highlight)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.hex("F5F5F7"),
                            Color(white: 0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .blur(radius: 1)
                        .offset(x: -1, y: -1)
                )
                .shadow(color: Color.gray.opacity(0.35), radius: 12, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.9), radius: 6, x: -3, y: -3)
                .scaleEffect(mobiScale)
                .position(center)
        }
        .allowsHitTesting(false)
    }

    private func handleHaptics(elapsed: Double) {
        // 7.0s: Silence (no haptic; vacuum moment).
        if elapsed >= 7.5, !haptic75Done {
            haptic75Done = true
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.prepare()
            gen.impactOccurred()
        }
    }

    private func handlePhase3Start(elapsed: Double) {
        if elapsed >= 7, !hasStartedPhase3 {
            hasStartedPhase3 = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                mobiScale = 1
            }
        }
    }

    private func handleAudioPhases(elapsed: Double) {
        guard let engine = audioEngine else { return }
        if elapsed >= 3, !hasTriggeredPhase2Audio {
            hasTriggeredPhase2Audio = true
            engine.triggerPhase2_Rise(duration: 4.0)
        }
        if elapsed >= 7, !hasTriggeredPhase3Audio {
            hasTriggeredPhase3Audio = true
            engine.triggerPhase3_Ping()
        }
    }
}

// MARK: - Preview

#Preview {
    SingularityTransitionView(onComplete: {})
}
