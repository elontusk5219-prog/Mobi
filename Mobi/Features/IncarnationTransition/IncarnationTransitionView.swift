//
//  IncarnationTransitionView.swift
//  Mobi
//
//  Phase 1: 0–23s flare → dissipation → black → genesis_transition.mp4.
//  Phase 2: Cosmic Sneeze (~5.5s) Void → Spark → Materialization → Sneeze → Connection.
//  onComplete called after Cosmic Sneeze ends.
//

import SwiftUI
import Combine

struct IncarnationTransitionView: View {
    let viewModel: GenesisViewModel
    var onComplete: () -> Void

    @State private var startTime: Date = .distantPast
    @State private var showCosmicSneeze = false
    @State private var incarnationViewModel: IncarnationViewModel?

    private let videoPhaseDuration: Double = 23.0

    var body: some View {
        ZStack {
            if showCosmicSneeze, let incarnationVM = incarnationViewModel {
                IncarnationSequenceView(viewModel: incarnationVM, onComplete: {
                    AudioPlayerService.shared.playOneShot(resource: "sfx_room_ber", ext: "mp3")
                    onComplete()
                })
                .transition(.opacity)
            } else {
                videoPhaseView
            }
        }
        .onAppear {
            startTime = Date()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                AudioPlayerService.shared.stopAmbient()
                try? await Task.sleep(nanoseconds: 500_000_000)
                AudioPlayerService.shared.playOneShot(resource: "sfx_genesis_boom", ext: "mp3")
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(videoPhaseDuration * 1_000_000_000))
                guard !showCosmicSneeze else { return }
                AudioPlayerService.shared.stopAmbient()
                let accent = viewModel.resolvedMobiConfig?.color ?? viewModel.finalSoulColor ?? Color(red: 0.3, green: 0.2, blue: 0.6)
                incarnationViewModel = IncarnationViewModel(accentColor: accent, visualDNA: viewModel.resolvedVisualDNA)
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCosmicSneeze = true
                }
            }
        }
    }

    @ViewBuilder
    private var videoPhaseView: some View {
        TimelineView(.animation) { timeline in
            let elapsed = startTime != .distantPast ? timeline.date.timeIntervalSince(startTime) : 0
            ZStack {
                Color.black.ignoresSafeArea()

                if elapsed < 8.0 {
                    AminaFluidView(elapsed: elapsed, state: .speaking, dominantColor: .cyan, vibeTremorIntensity: 0)
                        .brightness(elapsed < 4.0 ? (elapsed / 4.0) * 0.4 : 0.4)
                        .scaleEffect(elapsed > 4.0 ? 1.0 + (elapsed - 4.0) * 0.1 : 1.0)
                        .opacity(elapsed > 4.0 ? max(0.0, 1.0 - ((elapsed - 4.0) / 4.0)) : 1.0)
                }

                if elapsed >= 9.0 {
                    if GenesisVideoPlayerView.isVideoAvailable {
                        GenesisVideoPlayerView(elapsed: elapsed, triggerTime: 10.0)
                            .id("genesis_video")
                            .ignoresSafeArea()
                    } else {
                        GenesisVideoFallbackView(elapsed: elapsed)
                            .ignoresSafeArea()
                    }
                }
            }
        }
    }
}
