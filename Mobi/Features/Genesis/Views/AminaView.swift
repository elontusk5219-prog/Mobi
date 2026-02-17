//
//  AminaView.swift
//  Mobi
//
//  Fluid Multi-Color Blob (Gemini palette), LLM pulse, seamless Singularity overlay.
//

import SwiftUI

// MARK: - Gemini palette (fluid blob)

private let kFluidIndigo = Color(red: 0.3, green: 0.3, blue: 0.8)
private let kFluidCoral = Color(red: 1.0, green: 0.6, blue: 0.4)
private let kFluidMint = Color(red: 0.4, green: 0.9, blue: 0.7)
private let kFluidCyan = Color.cyan
private let kFluidColors: [Color] = [kFluidIndigo, kFluidCoral, kFluidMint, kFluidCyan]

struct AminaView: View {
    @ObservedObject var viewModel: GenesisViewModel
    @State private var isSoulTouched = false
    @State private var snapFlashOpacity: Double = 0
    @State private var pulseScale: CGFloat = 0.3
    @State private var pulseOpacity: Double = 0.5

    /// LLM pulse: blob "throbs" when AI is generating (thinking or speaking).
    private var isGenerating: Bool { viewModel.isThinking || viewModel.isSpeaking }
    private var fluidBaseScale: CGFloat {
        if viewModel.shouldTriggerGulp { return 1.2 }
        if viewModel.shouldTriggerTheSnap { return 0.05 }
        return isGenerating ? 1.05 : 1.0
    }

    var body: some View {
        GeometryReader { geometry in
            let c = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            ZStack {
                DeepSeaBackground(conversationTurn: viewModel.psycheModel.conversationTurn)

                // Fluid Multi-Color Blob — ink look via blur + multiply; time scaled by mood + TTS volume
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate * viewModel.fluidTurbulence * viewModel.audioReactiveTurbulence
                    fluidBlobLayer(size: geometry.size, center: c, t: t)
                }
                .scaleEffect(fluidBaseScale * (viewModel.isSpeaking ? viewModel.visualScale : 1.0))
                .animation(viewModel.shouldTriggerTheSnap ? .easeIn(duration: 0.5) : .easeOut(duration: 0.12), value: viewModel.shouldTriggerGulp)
                .animation(.easeIn(duration: 0.5), value: viewModel.shouldTriggerTheSnap)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isGenerating)
                .animation(.easeOut(duration: 0.2), value: viewModel.visualScale)
                .zIndex(1)
                .allowsHitTesting(!viewModel.isWakingUp)
                .disabled(viewModel.isWakingUp)
                .onTapGesture {
                    isSoulTouched = true
                    HapticEngine.shared.playLight()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in viewModel.setTouching(true) }
                        .onEnded { _ in viewModel.setTouching(false) }
                )

                ParticleImplosionOverlay(
                    trigger: viewModel.shouldTriggerImplosion,
                    center: c,
                    bounds: geometry.size
                )
                .allowsHitTesting(false)

                ParticleInjectionOverlay(
                    trigger: viewModel.shouldTriggerImplosion,
                    center: c,
                    bounds: geometry.size
                )
                .allowsHitTesting(false)

                LurePulseRing(center: c, isActive: viewModel.lureStage == .visualLure)
                    .zIndex(0)

                if let pulseColor = viewModel.pulseColor {
                    Circle()
                        .fill(pulseColor.opacity(pulseOpacity))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .position(c)
                        .blur(radius: 25)
                        .allowsHitTesting(false)
                        .zIndex(2)
                }

                Color.white
                    .opacity(viewModel.startupOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(viewModel.startupOpacity > 0.01)
                    .zIndex(10)

                if viewModel.isWakingUp {
                    VStack {
                        Spacer()
                        Text("Tuning Consciousness...")
                            .font(.caption)
                            .foregroundStyle(Color.primary.opacity(0.6))
                            .padding(.bottom, 48)
                    }
                    .zIndex(5)
                    .allowsHitTesting(false)
                }

                Color.white
                    .opacity(snapFlashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(20)
            }
        }
        .ignoresSafeArea()
        // Pre-transition: scale -> 0.05 (above) when shouldTriggerTheSnap. Birth is driven solely by SingularityTransitionView.onComplete in GenesisCoordinatorView.
        .onAppear {
            viewModel.triggerStartupSequence()
        }
        .onChange(of: viewModel.pulseColor) { _, newColor in
            if newColor != nil {
                pulseScale = 0.3
                pulseOpacity = 0.5
                withAnimation(.easeOut(duration: 2.5)) {
                    pulseScale = 2.2
                    pulseOpacity = 0
                }
            }
        }
    }

    // MARK: - Fluid blob (4 circles, sine-wave drift, blur + multiply for ink look)

    private func fluidBlobLayer(size: CGSize, center: CGPoint, t: TimeInterval) -> some View {
        let w = min(size.width, size.height)
        let baseRadius = w * 0.42
        return ZStack {
            ForEach(0..<4, id: \.self) { index in
                fluidCircle(index: index, baseRadius: baseRadius, center: center, t: t)
            }
        }
        .blur(radius: viewModel.fluidBlur)
        .blendMode(.multiply)
    }

    private func fluidCircle(index: Int, baseRadius: CGFloat, center: CGPoint, t: TimeInterval) -> some View {
        let i = Double(index)
        let freq1 = 0.35 + i * 0.12
        let freq2 = 0.28 + i * 0.09
        let phase1 = i * 0.7
        let phase2 = i * 1.3
        let amp = min(center.x, center.y) * 0.28
        let dx = sin(t * freq1 + phase1) * amp + cos(t * 0.18 + i) * amp * 0.4
        let dy = cos(t * freq2 + phase2) * amp + sin(t * 0.22 + i * 1.1) * amp * 0.4
        let radius = baseRadius * (0.85 + 0.15 * sin(t * 0.4 + i * 0.5))
        let color = viewModel.fluidColor?.swiftUIColor ?? kFluidColors[index % 4]
        let opacity: Double = viewModel.fluidColor == nil ? 0.88 : (0.85 + Double(index % 4) * 0.02)
        return Circle()
            .fill(color.opacity(opacity))
            .frame(width: radius * 2, height: radius * 2)
            .position(x: center.x + dx, y: center.y + dy)
    }
}
