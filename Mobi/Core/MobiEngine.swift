//
//  MobiEngine.swift
//  Mobi
//

import Foundation
import Combine

import SwiftUI

@MainActor
final class MobiEngine: ObservableObject {
    @Published private(set) var lifeStage: LifeStage = .genesis
    @Published private(set) var activityState: ActivityState = .idle
    @Published private(set) var interactionCount: Int = 0
    /// Birth config from Genesis transition; Room reads this for Mobi color/appearance.
    @Published var resolvedMobiConfig: ResolvedMobiConfig?
    /// Visual DNA from Genesis (LLM or default). Room passes to ProceduralMobiView.
    @Published var resolvedVisualDNA: MobiVisualDNA?
    /// Persona JSON from SoulProfile for Room Doubao session.
    @Published var roomPersonaPrompt: String?
    /// Live STT transcript for debug overlay (set by Doubao/Voice service).
    @Published var currentTranscript: String = ""
    /// AI mood for Genesis ambient DSP (debug-settable; later from LLM/Doubao).
    @Published private(set) var currentMood: MobiMood = .neutral

    /// Birth condition: after this many interactions in Genesis (15-turn Protocol), trigger transition to Room (Phase 2).
    private let birthThreshold = 15
    private let evolutionManager: EvolutionManager

    static let shared: MobiEngine = {
        MobiEngine(evolutionManager: EvolutionManager.shared)
    }()

    init(evolutionManager: EvolutionManager) {
        self.evolutionManager = evolutionManager
    }

    func recordInteraction() {
        guard lifeStage == .genesis else { return }
        interactionCount += 1
        print("[MobiEngine] Interaction Count: \(interactionCount)/\(birthThreshold)")
        if interactionCount >= birthThreshold {
            triggerBirth()
        }
    }

    func triggerBirth() {
        guard lifeStage == .genesis else { return }
        lifeStage = .newborn
        evolutionManager.setStage(.newborn)
    }

    /// Called at IncarnationTransition onComplete to persist birth config for Room.
    func setResolvedMobiConfig(_ config: ResolvedMobiConfig?) {
        resolvedMobiConfig = config
    }

    /// Called at IncarnationTransition onComplete to persist Visual DNA for Room.
    func setResolvedVisualDNA(_ dna: MobiVisualDNA?) {
        resolvedVisualDNA = dna
    }

    /// Set Room persona from SoulProfile JSON (call alongside setResolvedMobiConfig).
    func setRoomPersona(_ personaJSON: String?) {
        roomPersonaPrompt = personaJSON
    }

    /// 切换账号时调用，清空当前用户专属状态，避免串号。由 AuthView 在 login/register 后调用。
    func clearUserSpecificState() {
        resolvedMobiConfig = nil
        resolvedVisualDNA = nil
        roomPersonaPrompt = nil
        interactionCount = 0
        lifeStage = .genesis
        print("[MobiEngine] clearUserSpecificState: config/dna/persona cleared, lifeStage=genesis")
    }

    func setActivityState(_ state: ActivityState) {
        let prev = activityState
        activityState = state
        print("[MobiEngine] ActivityState: \(prev.rawValue) → \(state.rawValue)")
    }

    func setCurrentMood(_ mood: MobiMood) {
        currentMood = mood
    }

    func forceEvolve(targetStage: LifeStage) {
        lifeStage = targetStage
        evolutionManager.forceEvolve(targetStage: targetStage)
    }

    /// Hard reset: interactionCount = 0, lifeStage = .genesis, for Debug "System Reset". Caller should disconnect/reconnect Doubao.
    func resetToGenesis() {
        interactionCount = 0
        lifeStage = .genesis
        evolutionManager.forceEvolve(targetStage: .genesis)
        print("[MobiEngine] System Reset: interactionCount=0, lifeStage=.genesis")
    }

    /// Debug: jump to N-th turn (0..<15). Only in Genesis. E.g. 13 = "last two rounds" (14, 15 then Incarnation).
    func debugSetInteractionCount(_ value: Int) {
        guard lifeStage == .genesis else { return }
        let clamped = min(max(0, value), birthThreshold - 1)
        interactionCount = clamped
        print("[MobiEngine] Debug: interactionCount = \(interactionCount) (last \(birthThreshold - interactionCount) rounds left)")
    }

    var evolution: EvolutionManager { evolutionManager }

    /// Call when user is silent too long; sends a hidden text instruction so Anima says something.
    func triggerProactiveConversation() {
        print("[Mobi] User is silent. Poking Anima...")
        DoubaoRealtimeService.shared.sendTextInstruction("The user is staring at you but not speaking. Say something short to greet them or ask what they are thinking.")
    }
}
