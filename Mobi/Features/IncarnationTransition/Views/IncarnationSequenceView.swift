//
//  IncarnationSequenceView.swift
//  Mobi
//
//  Cosmic Sneeze: Void → Spark → Materialization → Sneeze → Connection.
//  ZStack: Room → Mobi → Light mask → Black overlay → Particles → UI.
//

import SwiftUI

struct IncarnationSequenceView: View {
    @ObservedObject var viewModel: IncarnationViewModel
    var onComplete: () -> Void

    @State private var startTime = Date.distantPast
    @State private var hasTriggeredPhase0Haptic = false
    @State private var hasTriggeredPhase1Audio = false
    @State private var hasTriggeredPhase2Audio = false
    @State private var hasTriggeredPhase3Audio = false
    @State private var hasTriggeredPhase3Haptic = false
    @State private var hasTriggeredPhase4Audio = false
    @State private var hasTriggeredPhase4BGM = false

    private let goldDustCount = 12
    private let sneezePuffCount = 8

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { timeline in
            let elapsed = startTime != .distantPast ? timeline.date.timeIntervalSince(startTime) : 0
            let _ = viewModel.update(elapsed: elapsed)
            incarnationContent
        }
        .onAppear {
            startTime = Date()
            viewModel.onSequenceComplete = onComplete
        }
    }

    @ViewBuilder
    private var incarnationContent: some View {
        GeometryReader { geo in
            let size = geo.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            ZStack {
                // Layer A: Room background (starts black/revealed by light)
                roomBackground(size: size)
                    .opacity(viewModel.currentPhase == .void ? 0 : 1)

                // Layer B: Mobi character (appears in Phase 2 Materialization)
                if viewModel.currentPhase == .shaking || viewModel.currentPhase == .sneezing || viewModel.currentPhase == .alive {
                    mobiView(size: size, center: center)
                }

                // Layer C: Black overlay – mask with expanding "hole" for light reveal
                Color.black
                    .ignoresSafeArea()
                    .mask(blackOverlayMask)

                // Layer D: Gold dust particles (Phase 2)
                if viewModel.goldDustActive {
                    goldDustLayer(size: size, center: center)
                }

                // Layer E: Sneeze puff (Phase 3)
                if viewModel.sneezePuffActive {
                    sneezePuffLayer(size: size, center: center)
                }

                // Layer F: UI placeholder (Phase 4)
                if viewModel.currentPhase == .alive {
                    uiPlaceholder
                        .opacity(viewModel.uiOpacity)
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.currentPhase) { _, phase in
            triggerPhaseEffects(phase: phase)
        }
        .onAppear {
            triggerPhaseEffects(phase: viewModel.currentPhase)
        }
    }

    // MARK: - Room Background

    @ViewBuilder
    private func roomBackground(size: CGSize) -> some View {
        if UIImage(named: "HomeBackground") != nil {
            Image("HomeBackground")
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            RoomParallaxBackground(themeColor: viewModel.accentColor, parallaxOffset: .zero)
                .frame(width: size.width, height: size.height)
        }
    }

    // MARK: - Black Overlay Mask (expanding circle reveals room)

    private var blackOverlayMask: some View {
        GeometryReader { geo in
            let maxR = max(geo.size.width, geo.size.height) * 1.2
            let r = maxR * viewModel.sparkMaskProgress
            ZStack {
                Rectangle().fill(.white)
                Circle()
                    .fill(.black)
                    .frame(width: max(1, r * 2), height: max(1, r * 2))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }

    // MARK: - Mobi

    private func mobiView(size: CGSize, center: CGPoint) -> some View {
        Group {
            if UIImage(named: "CartoonMobi") != nil {
                Image("CartoonMobi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width * 0.5, height: size.width * 0.5)
            } else {
                ProceduralMobiView(
                    primaryColor: viewModel.accentColor,
                    dna: viewModel.visualDNA,
                    dragStretch: .zero,
                    isSpeaking: false,
                    isListening: false,
                    lookDirection: .zero,
                    lifeStage: .newborn,
                    onPoke: nil
                )
                .frame(width: size.width * 0.5, height: size.width * 0.5)
            }
        }
        .scaleEffect(viewModel.mobiScale)
        .scaleEffect(x: 1, y: viewModel.sneezeScaleY)
        .rotationEffect(.degrees(viewModel.shakeAngle + viewModel.headTilt))
        .position(center)
    }

    // MARK: - Gold Dust

    private func goldDustLayer(size: CGSize, center: CGPoint) -> some View {
        ZStack {
            ForEach(0..<goldDustCount, id: \.self) { i in
                let t = viewModel.elapsed - 2.0
                let seed = Double(i) / Double(goldDustCount)
                let angle = seed * .pi * 0.6 + .pi * 0.2
                let dist = 20 + t * 80 + Double(i % 3) * 25
                let x = center.x + cos(angle) * dist * 2
                let y = center.y + sin(angle) * dist + t * 60
                let opacity = max(0, 0.8 - t * 0.5)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow, .orange.opacity(0.6), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 6
                        )
                    )
                    .frame(width: 10, height: 10)
                    .position(x: x, y: y)
                    .opacity(opacity)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Sneeze Puff

    private func sneezePuffLayer(size: CGSize, center: CGPoint) -> some View {
        ZStack {
            ForEach(0..<sneezePuffCount, id: \.self) { i in
                let t = viewModel.elapsed - 3.15
                let progress = min(1, t / 0.65)
                let angle = Double(i) / Double(sneezePuffCount) * .pi * 2
                let r = 15 + progress * 50
                let x = center.x + cos(angle) * r
                let y = center.y - 30 + sin(angle) * r * 0.5 - progress * 20
                Circle()
                    .fill(.white.opacity(0.7))
                    .frame(width: 8 + progress * 12, height: 8 + progress * 8)
                    .blur(radius: 2)
                    .position(x: x, y: y)
                    .opacity(max(0, 1 - progress))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - UI Placeholder

    private var uiPlaceholder: some View {
        VStack {
            Spacer()
            Circle()
                .fill(viewModel.accentColor.opacity(0.3))
                .frame(width: 64, height: 64)
                .overlay(Image(systemName: "mic.fill").font(.title2).foregroundStyle(.white))
                .padding(.bottom, 50)
        }
    }

    // MARK: - Phase Effects (audio, haptics)

    private func triggerPhaseEffects(phase: IncarnationPhase) {
        switch phase {
        case .void:
            if !hasTriggeredPhase0Haptic {
                hasTriggeredPhase0Haptic = true
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                AudioPlayerService.shared.playOneShot(resource: "sfx_vacuum_silence", ext: "mp3")
            }
        case .spark:
            if !hasTriggeredPhase1Audio {
                hasTriggeredPhase1Audio = true
                AudioPlayerService.shared.playOneShot(resource: "sfx_spark_ignite", ext: "mp3")
            }
        case .shaking:
            if !hasTriggeredPhase2Audio {
                hasTriggeredPhase2Audio = true
                AudioPlayerService.shared.playOneShot(resource: "sfx_shake_fur", ext: "mp3")
            }
        case .sneezing:
            if !hasTriggeredPhase3Audio {
                hasTriggeredPhase3Audio = true
                AudioPlayerService.shared.playOneShot(resource: "sfx_sneeze_cute", ext: "mp3")
            }
            if !hasTriggeredPhase3Haptic {
                hasTriggeredPhase3Haptic = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        case .alive:
            if !hasTriggeredPhase4Audio {
                hasTriggeredPhase4Audio = true
                AudioPlayerService.shared.playOneShot(resource: "sfx_curious_gu", ext: "mp3")
            }
            if !hasTriggeredPhase4BGM {
                hasTriggeredPhase4BGM = true
                AudioPlayerService.shared.playOneShot(resource: "bgm_room_ambience", ext: "mp3")
            }
        }
    }
}
