//
//  GenesisVisuals.swift
//  Mobi
//
//  Gemini-Live style: Canvas + TimelineView. Fluid Nebula, Primordial palette.
//

import SwiftUI

// MARK: - Color + Interpolation (Soul Warmth: blue 0.0 ↔ orange 1.0)

private extension Color {
    static func soulWarmth(amount: Double) -> Color {
        let a = min(1, max(0, amount))
        return Color(
            red: (1 - a) * 0.2 + a * 1.0,
            green: (1 - a) * 0.4 + a * 0.5,
            blue: (1 - a) * 1.0 + a * 0.1
        )
    }
}

// MARK: - Luminous Sea Background (#F5F5F7 + fluid Voronoi)

private let kVoronoiCols = 14
private let kVoronoiRows = 10

struct DeepSeaBackground: View {
    /// Current conversation turn; 11–15 increases ripple frequency (Shaping).
    var conversationTurn: Int = 0

    private var rippleFrequency: Double {
        guard conversationTurn >= 11 else { return 1.0 }
        return 1.0 + Double(conversationTurn - 11) * 0.22
    }

    var body: some View {
        ZStack {
            Color.hex("F5F5F7")
                .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let freq = rippleFrequency
                    let cellW = size.width / CGFloat(kVoronoiCols)
                    let cellH = size.height / CGFloat(kVoronoiRows)
                    for row in 0..<kVoronoiRows {
                        for col in 0..<kVoronoiCols {
                            let seed = Double(row * kVoronoiCols + col) * 0.31
                            let cx = cellW * (CGFloat(col) + 0.5) + sin(t * 0.3 * freq + seed) * cellW * 0.22
                            let cy = cellH * (CGFloat(row) + 0.5) + cos(t * 0.25 * freq + seed * 1.1) * cellH * 0.22
                            let r = min(cellW, cellH) * (0.42 + sin(t * 0.5 * freq + seed * 2) * 0.1)
                            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                            let opacity = 0.05 + sin(t * freq + seed) * 0.03
                            context.opacity = Double(opacity)
                            context.fill(Path(ellipseIn: rect), with: .color(.white))
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Gemini four-color system (Luminous Sea)

private let kColorIndigo = Color(red: 0.29, green: 0.22, blue: 0.49)
private let kColorMint = Color(red: 0.40, green: 0.85, blue: 0.75)
private let kColorCoral = Color(red: 0.98, green: 0.45, blue: 0.42)
private let kColorCyan = Color(red: 0.35, green: 0.78, blue: 0.92)

// MARK: - NebulaSoulView (four-color blend + glass/Fresnel core)

struct NebulaSoulView: View {
    @ObservedObject var viewModel: GenesisViewModel
    @ObservedObject var psycheModel: UserPsycheModel
    @Binding var isTouched: Bool

    @State private var touchScale: CGFloat = 1.0

    /// T=warmth, E=energy, Chaos=chaos. Normalized blend: WeightIndigo=(1-T)*(1-E), WeightCoral=T*E, WeightCyan=(1-Chaos), WeightMint=E*Chaos.
    private var blendedSoulColor: Color {
        let T = min(1, max(0, psycheModel.warmth))
        let E = min(1, max(0, psycheModel.energy))
        let C = min(1, max(0, psycheModel.chaos))
        var wI = (1 - T) * (1 - E)
        var wCoral = T * E
        var wCyan = 1 - C
        var wMint = E * C
        let sum = wI + wCoral + wCyan + wMint
        if sum > 0.001 {
            wI /= sum; wCoral /= sum; wCyan /= sum; wMint /= sum
        }
        return Color(
            red: wI * 0.29 + wCoral * 0.98 + wCyan * 0.35 + wMint * 0.40,
            green: wI * 0.22 + wCoral * 0.45 + wCyan * 0.78 + wMint * 0.85,
            blue: wI * 0.49 + wCoral * 0.42 + wCyan * 0.92 + wMint * 0.75
        )
    }

    /// Fallback theme tint from MobiSeed (used as multiplier).
    private var warmthColor: Color {
        viewModel.mobiSeed.themeColor
    }

    private let whiteCore = Color.white

    /// Pulse duration from MobiSeed energy: higher = faster (0.5–1.0 s).
    private var pulseDuration: Double {
        let e = min(max(viewModel.mobiSeed.energy, 0), 1)
        return 1.0 - (e * 0.5)
    }

    /// Blur: high structure → low blur (geometric); low structure → high blur (fluid).
    private var structureBlur: CGFloat {
        let s = min(max(viewModel.mobiSeed.structure, 0), 1)
        return 5 + CGFloat(1 - s) * 25
    }

    /// Sensory progression: 0 = distant, 1 = intimate. Drives blur 30→0, pulse 0.5→2 Hz, brightness.
    private var sensoryProgress: Double {
        psycheModel.sensoryProgress
    }

    /// Progression blur: 30px at start → 0px at end (distance to intimacy).
    private var progressionBlur: CGFloat {
        30 * CGFloat(1 - sensoryProgress)
    }

    /// Combined blur: structure + progression. Turn 11–15 (Shaping): reduce blur for crystal feel.
    private var totalBlur: CGFloat {
        let base = structureBlur + progressionBlur
        let turn = psycheModel.conversationTurn
        if turn >= 11 {
            let shaping = CGFloat(turn - 11) / 4.0
            return base * (1.0 - shaping * 0.6)
        }
        return base
    }

    /// Refraction / Fresnel strength 0...1 for turn 11–15 (glass core).
    private var refractionStrength: CGFloat {
        let turn = psycheModel.conversationTurn
        guard turn >= 11 else { return 0 }
        return min(1, CGFloat(turn - 11) / 4.0)
    }

    /// Progression pulse period (s): 0.5 Hz = 2s period → 2 Hz = 0.5s period.
    private var progressionPulsePeriod: Double {
        let freq = 0.5 + 1.5 * sensoryProgress
        return 1.0 / freq
    }

    /// Blended pulse period: energy-based when progress low, progression-driven when high.
    private var effectivePulsePeriod: Double {
        (1 - sensoryProgress) * pulseDuration + sensoryProgress * progressionPulsePeriod
    }

    /// Core brightness: exponential near end (pow(progress, 2)).
    private var coreBrightness: Double {
        pow(sensoryProgress, 2)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let showDrift = viewModel.timeSinceLastInteraction > 6.0
            let drift: CGSize = showDrift
                ? CGSize(width: sin(t) * 50, height: cos(t * 0.7) * 80)
                : .zero
            let anxietyTint: Color = showDrift ? Color.orange.opacity(0.25) : .white
            let mysteryPurpleTint: Color = viewModel.lureStage == .cognitiveLure ? Color.purple.opacity(0.5) : .white
            let pulseScale = 1.0 + 0.05 * sin(t * (2 * .pi) / effectivePulsePeriod)

            soulCanvas(t: t)
                .offset(drift)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showDrift)
                .colorMultiply(blendedSoulColor)
                .colorMultiply(anxietyTint)
                .colorMultiply(mysteryPurpleTint)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.lureStage)
                .blur(radius: totalBlur)
                .overlay {
                    Color.white.opacity(coreBrightness * 0.4)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                }
                .overlay {
                    if refractionStrength > 0 {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.35 * Double(refractionStrength)), lineWidth: 2)
                            .blur(radius: 1)
                            .blendMode(.plusLighter)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    if min(max(viewModel.mobiSeed.structure, 0), 1) < 0.5 {
                        CloudShape(time: t)
                            .blendMode(.plusLighter)
                            .allowsHitTesting(false)
                    }
                }
                .scaleEffect(max(0.3, pulseScale * touchScale * viewModel.visualScale))
        }
        .onChange(of: isTouched) { _, newValue in
            guard newValue else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                touchScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    touchScale = 1.0
                }
                isTouched = false
            }
        }
    }

    private func soulCanvas(t: TimeInterval) -> some View {
        let speedMult: Double = viewModel.isListening ? 3.0 : 1.0
        let whiteCoreScale: CGFloat = viewModel.isListening ? (1.0 + CGFloat(viewModel.visualScale - 1.0) * 0.5) : 1.0
        let breath: CGFloat = viewModel.isThinking ? (1.0 + 0.2 * sin(t * 8)) : 1.0
        let size: CGFloat = 220
        let cx = size / 2
        let cy = size / 2
        let baseR: CGFloat = min(size, size) / 3 * breath
        let breathOpacity = 0.5 + 0.15 * sin(t * 6)

        // Layer 1: Outer atmosphere — four-color blend, heavy blur (liquid depth)
        let outerRotations: [(Double, CGFloat)] = [
            (2.0 * speedMult, baseR * 1.4),
            (1.3 * speedMult, baseR * 1.3),
            (1.7 * speedMult, baseR * 1.2)
        ]
        let outerLayer = ZStack {
            ForEach(Array(outerRotations.enumerated()), id: \.offset) { _, item in
                let (speed, radius) = item
                let angle = t * speed
                let x = cx + cos(angle) * radius * 0.6
                let y = cy + sin(angle) * radius * 0.5
                Circle()
                    .fill(kColorIndigo.opacity(0.55))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: x, y: y)
                    .blur(radius: 50)
            }
        }
        .blendMode(.plusLighter)

        // Layer 2: Inner glow — Gemini four colors, medium blur
        let innerRotations: [(Double, CGFloat, Color)] = [
            (2.0 * speedMult, baseR * 0.9, kColorCyan),
            (1.3 * speedMult, baseR * 0.85, kColorMint),
            (1.7 * speedMult, baseR * 0.8, kColorCoral)
        ]
        let innerLayer = ZStack {
            ForEach(Array(innerRotations.enumerated()), id: \.offset) { _, item in
                let (speed, radius, color) = item
                let angle = t * speed
                let x = cx + cos(angle) * radius * 0.6
                let y = cy + sin(angle) * radius * 0.5
                Circle()
                    .fill(color.opacity(0.6))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: x, y: y)
                    .blur(radius: 18)
            }
        }
        .blendMode(.plusLighter)

        // Layer 3: Core — white, low blur (glass highlight)
        let coreRadius = baseR * 0.5 * whiteCoreScale
        let coreAngle = t * 0.8 * speedMult
        let coreX = cx + cos(coreAngle) * coreRadius * 0.6
        let coreY = cy + sin(coreAngle) * coreRadius * 0.5
        let coreLayer = Circle()
            .fill(whiteCore.opacity(0.78 * breathOpacity))
            .frame(width: coreRadius * 2, height: coreRadius * 2)
            .position(x: coreX, y: coreY)
            .blur(radius: 5)
            .blendMode(.plusLighter)

        return ZStack {
            outerLayer
            innerLayer
            coreLayer
        }
        .frame(width: size, height: size)
        .colorMultiply(viewModel.isThinking ? Color(white: 0.92) : .white)
    }
}

// MARK: - CloudShape (High Chaos: fluid overlay)

private struct CloudShape: View {
    let time: TimeInterval
    private let size: CGFloat = 220

    var body: some View {
        Canvas { context, canvasSize in
            let cx = size / 2
            let cy = size / 2
            for i in 0..<6 {
                let phase = time * 0.4 + Double(i) * 0.7
                let r = 40 + sin(phase) * 25
                let x = cx + cos(phase * 1.2) * 50
                let y = cy + sin(phase * 0.9) * 45
                let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                context.opacity = 0.2 + sin(phase + Double(i)) * 0.1
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
        .frame(width: size, height: size)
        .blur(radius: 20)
    }
}

// MARK: - Lure Pulse Ring (Stage 1: faint ring expanding from core)

struct LurePulseRing: View {
    let center: CGPoint
    let isActive: Bool

    var body: some View {
        if isActive {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let scale = 0.3 + (t.truncatingRemainder(dividingBy: 2.0) / 2.0) * 1.2
                let opacity = 0.25 * (1.0 - (t.truncatingRemainder(dividingBy: 2.0) / 2.0))
                Circle()
                    .stroke(Color.white.opacity(opacity), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)
                    .position(center)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Particle Implosion (Listening -> Thinking)

struct ParticleImplosionOverlay: View {
    let trigger: Bool
    let center: CGPoint
    let bounds: CGSize

    private let particleCount = 16

    var body: some View {
        ZStack {
            if trigger {
                ForEach(0..<particleCount, id: \.self) { i in
                    ImplosionParticle(
                        index: i,
                        total: particleCount,
                        center: center,
                        bounds: bounds
                    )
                }
            }
        }
    }
}

private struct ImplosionParticle: View {
    let index: Int
    let total: Int
    let center: CGPoint
    let bounds: CGSize

    @State private var progress: CGFloat = 0
    @State private var startPoint: CGPoint = .zero

    var body: some View {
        let x = startPoint.x + (center.x - startPoint.x) * progress
        let y = startPoint.y + (center.y - startPoint.y) * progress
        let opacity = 1.0 - Double(progress)
        return Circle()
            .fill(Color.white)
            .frame(width: 6, height: 6)
            .position(x: x, y: y)
            .opacity(opacity)
            .onAppear {
                startPoint = edgePoint(for: index)
                withAnimation(.easeIn(duration: 0.45)) {
                    progress = 1
                }
            }
    }

    private func edgePoint(for index: Int) -> CGPoint {
        let w = bounds.width
        let h = bounds.height
        let t = CGFloat(index) / CGFloat(total)
        if t < 0.25 {
            return CGPoint(x: CGFloat.random(in: 0...w), y: 0)
        } else if t < 0.5 {
            return CGPoint(x: w, y: CGFloat.random(in: 0...h))
        } else if t < 0.75 {
            return CGPoint(x: CGFloat.random(in: 0...w), y: h)
        } else {
            return CGPoint(x: 0, y: CGFloat.random(in: 0...h))
        }
    }
}

// MARK: - Particle Injection (Listening -> Thinking, "The Feeding")

/// ~50 particles from screen edges flying into the core ("The Gulp"). Triggered on listening→thinking; gulp scale applied by ViewModel after delay.
struct ParticleInjectionOverlay: View {
    let trigger: Bool
    let center: CGPoint
    let bounds: CGSize

    private let particleCount = 50
    private let flightDuration: Double = 0.4

    var body: some View {
        ZStack {
            if trigger {
                ForEach(0..<particleCount, id: \.self) { i in
                    InjectionParticle(
                        index: i,
                        total: particleCount,
                        center: center,
                        bounds: bounds,
                        flightDuration: flightDuration
                    )
                }
            }
        }
    }
}

private struct InjectionParticle: View {
    let index: Int
    let total: Int
    let center: CGPoint
    let bounds: CGSize
    let flightDuration: Double

    @State private var progress: CGFloat = 0
    @State private var startPoint: CGPoint = .zero

    private var color: Color { index % 2 == 0 ? Color(red: 1, green: 0.84, blue: 0) : Color.white }

    var body: some View {
        let x = startPoint.x + (center.x - startPoint.x) * progress
        let y = startPoint.y + (center.y - startPoint.y) * progress
        let opacity = progress < 0.85 ? 1.0 : (1.0 - (progress - 0.85) / 0.15)
        return Capsule()
            .fill(color)
            .frame(width: 4, height: 8)
            .position(x: x, y: y)
            .opacity(opacity)
            .onAppear {
                startPoint = injectionEdgePoint(for: index)
                withAnimation(.easeIn(duration: flightDuration)) {
                    progress = 1
                }
            }
    }

    private func injectionEdgePoint(for index: Int) -> CGPoint {
        let w = bounds.width
        let h = bounds.height
        let t = CGFloat(index) / CGFloat(total)
        if t < 0.25 {
            return CGPoint(x: (CGFloat(index) * 1.7).truncatingRemainder(dividingBy: w), y: 0)
        } else if t < 0.5 {
            return CGPoint(x: w, y: (CGFloat(index) * 1.3).truncatingRemainder(dividingBy: h))
        } else if t < 0.75 {
            return CGPoint(x: (CGFloat(index) * 1.7).truncatingRemainder(dividingBy: w), y: h)
        } else {
            return CGPoint(x: 0, y: (CGFloat(index) * 1.3).truncatingRemainder(dividingBy: h))
        }
    }
}
