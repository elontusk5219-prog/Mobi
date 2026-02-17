//
//  GenesisCoordinatorView.swift
//  Mobi
//

import SwiftUI

struct GenesisCoordinatorView: View {
    let container: DependencyContainer
    @ObservedObject private var engine: MobiEngine
    @StateObject private var viewModel: GenesisViewModel
    private let onComplete: () -> Void
    private let onJumpToRoom: ((LifeStage) -> Void)?

    @State private var showSingularityTransition = false

    init(container: DependencyContainer, onComplete: @escaping () -> Void, onJumpToRoom: ((LifeStage) -> Void)? = nil) {
        self.container = container
        _engine = ObservedObject(wrappedValue: container.mobiEngine)
        _viewModel = StateObject(wrappedValue: GenesisViewModel(
            audioVisualizer: container.audioVisualizerService,
            ambientSoundService: container.ambientSoundService,
            engine: container.mobiEngine
        ))
        self.onComplete = onComplete
        self.onJumpToRoom = onJumpToRoom
    }

    /// When true, shows the Ethereal Fluid Orb (AminaFluidView); when false, Soul Distillation liquid (AnimaLiquidView).
    private static let useEtherealOrb = true

    var body: some View {
        ZStack {
            // Base layer: Ethereal Fluid Orb or Soul Distillation liquid
            if Self.useEtherealOrb {
                AminaFluidView(
                    state: viewModel.animaState,
                    dominantColor: viewModel.animaMainColor,
                    vibeTremorIntensity: viewModel.vibeTremorIntensity,
                    audioPower: viewModel.audioPower,
                    ttsOutputLevel: viewModel.ttsOutputLevel,
                    reflexOffsetY: viewModel.reflexOffsetY
                )
            } else {
                AnimaLiquidView(viewModel: viewModel)
            }

            DebugOverlayView(engine: engine, doubao: container.doubaoRealtimeService, psycheModel: viewModel.psycheModel, soulMetadata: viewModel.soulMetadata, onJumpToRoom: onJumpToRoom)

            // Overlay: Incarnation 10s (Sphere warp → Phantom → Cartoon) then complete. Contract: onComplete must call finishSnapAndBirth() then onComplete() so Anima→Mobi handoff stays correct.
            if showSingularityTransition {
                IncarnationTransitionView(viewModel: viewModel, onComplete: {
                    viewModel.isTransitionActive = false
                    engine.setResolvedMobiConfig(viewModel.resolvedMobiConfig)
                    engine.setResolvedVisualDNA(viewModel.resolvedVisualDNA)
                    let persona = viewModel.resolvedRoomPersona ?? viewModel.psycheModel.buildSoulProfile().toJSONSummary()
                    engine.setRoomPersona(persona)
                    viewModel.finishSnapAndBirth()
                    withAnimation(.easeInOut(duration: 1.5)) { showSingularityTransition = false }
                    onComplete()
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.5), value: showSingularityTransition)
        .onAppear {
            viewModel.triggerStartupSequence()
            viewModel.startGenesisAmbient()
            DoubaoRealtimeService.shared.onChatContent = { [viewModel] text in
                Task { @MainActor in viewModel.processLLMResponse(text: text) }
            }
            DoubaoRealtimeService.shared.onChatContentIncremental = { [viewModel] accumulated in
                Task { @MainActor in viewModel.handleChatContentIncremental(accumulated) }
            }
            DoubaoRealtimeService.shared.onUserUtterance = { [viewModel] text in
                Task { @MainActor in viewModel.processUserInputFromASR(text: text) }
            }
        }
        .onDisappear {
            DoubaoRealtimeService.shared.onChatContent = nil
            DoubaoRealtimeService.shared.onChatContentIncremental = nil
            DoubaoRealtimeService.shared.onUserUtterance = nil
            viewModel.stopGenesisAmbient()
            HeartbeatEngine.shared.stop()
            DoubaoRealtimeService.shared.disconnect()
        }
        .onChange(of: viewModel.shouldTriggerTheSnap) { _, new in
            if new {
                viewModel.commitProfileAndStartGeneration()
                viewModel.isTransitionActive = true
                withAnimation(.easeInOut(duration: 1.5)) { showSingularityTransition = true }
            }
        }
        .onChange(of: viewModel.showIncarnationTransition) { _, new in
            if new {
                viewModel.commitProfileAndStartGeneration()
                viewModel.isTransitionActive = true
                withAnimation(.easeInOut(duration: 1.5)) { showSingularityTransition = true }
            }
        }
        .onChange(of: engine.lifeStage) { _, newStage in
            if newStage == .newborn { onComplete() }
        }
    }
}
