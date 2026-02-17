//
//  MobiApp.swift
//  Mobi
//

import Combine
import SwiftUI

private struct AuthGateBindingKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

extension EnvironmentValues {
    var authGateBinding: Binding<Bool>? {
        get { self[AuthGateBindingKey.self] }
        set { self[AuthGateBindingKey.self] = newValue }
    }
}

@main
struct MobiApp: App {
    @State private var container = DependencyContainer()
    @State private var showAuthGate = true
    @State private var showRoom = UserIdentityService.currentUserHasCompletedAnima
    @State private var featherWhiteOpacity: Double = 1.0

    var body: some Scene {
        WindowGroup {
            if showAuthGate {
                AuthView(onSuccess: {
                    showAuthGate = false
                    showRoom = UserIdentityService.currentUserHasCompletedAnima
                })
            } else {
                mainContent
                    .environment(\.authGateBinding, $showAuthGate)
            }
        }
    }

    private var mainContent: some View {
        Group {
            if showRoom {
                ZStack {
                    RoomContainerView(container: container)
                        .environmentObject(container.mobiEngine)
                    Color.white
                        .opacity(featherWhiteOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.5)) { featherWhiteOpacity = 0 }
                }
            } else {
                GenesisCoordinatorView(
                    container: container,
                    onComplete: {
                        UserIdentityService.markAnimaCompleted(for: UserIdentityService.currentUserId)
                        showRoom = true
                    },
                    onJumpToRoom: { stage in
                        let engine = container.mobiEngine
                        let evolution = EvolutionManager.shared
                        evolution.forceEvolve(targetStage: stage)
                        if engine.resolvedMobiConfig == nil {
                            engine.setResolvedMobiConfig(ResolvedMobiConfig.fallback)
                        }
                        if engine.resolvedVisualDNA == nil {
                            engine.setResolvedVisualDNA(.default)
                        }
                        if engine.roomPersonaPrompt == nil {
                            engine.setRoomPersona("You are Mobi, warm and curious.")
                        }
                        UserIdentityService.markAnimaCompleted(for: UserIdentityService.currentUserId)
                        showRoom = true
                    }
                )
                .environmentObject(container.mobiEngine)
            }
        }
    }
}
