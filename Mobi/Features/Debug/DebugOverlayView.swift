//
//  DebugOverlayView.swift
//  Mobi
//

import SwiftUI

struct DebugOverlayView: View {
    @ObservedObject var engine: MobiEngine
    @ObservedObject var doubao: DoubaoRealtimeService
    /// When non-nil (e.g. from GenesisCoordinatorView), T/E/S sliders are shown for real-time orb tuning.
    var psycheModel: UserPsycheModel? = nil
    /// 15-Turn Soul Profiler: when non-nil, show turn/stage/trait/color/erosion in expanded debug.
    var soulMetadata: SoulMetadata? = nil
    /// When non-nil (e.g. in Anima), jump to Room at given stage; else only forceEvolve in-place.
    var onJumpToRoom: ((LifeStage) -> Void)? = nil
    /// When non-nil (e.g. in Room), 跳 newborn/child 后立即发送该阶段第一个剧本。
    var onStageJumpInRoom: ((LifeStage) -> Void)? = nil
    @State private var isExpanded = false
    @State private var showSettings = false

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: 0) {
                    Button(action: { isExpanded.toggle() }) {
                        Text(isExpanded ? "▼ Debug" : "▲ Debug")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(8)
                    if isExpanded { expandedContent }
                }
                .background(Color.black.opacity(0.5))
            }
            .overlay(alignment: .bottom) {
                liveEarSection
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("State: \(engine.activityState.rawValue)")
                .font(.caption)
                .foregroundStyle(.white)
            Text("Stage: \(engine.evolution.currentStage.rawValue)")
                .font(.caption)
                .foregroundStyle(.white)
            Text("Doubao: \(doubao.connectionStatus)")
                .font(.caption)
                .foregroundStyle(doubao.connectionStatus == "Connected" ? .green : .white)
            if let meta = soulMetadata {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Soul: turn \(meta.turn) · \(meta.stage)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("trait: \(meta.trait) · \(meta.color) · erosion \(String(format: "%.2f", meta.erosion))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            if let psyche = psycheModel {
                TESSlidersSectionView(psyche: psyche)
            }
            HStack(spacing: 6) {
                Button("跳到最后两轮") {
                    engine.debugSetInteractionCount(13)
                }
                ForEach([LifeStage.newborn, .child, .adult], id: \.rawValue) { stage in
                    Button("跳 Mobi \(stage.rawValue)") {
                        if let jump = onJumpToRoom {
                            jump(stage)
                        } else {
                            engine.forceEvolve(targetStage: stage)
                            onStageJumpInRoom?(stage)
                        }
                    }
                }
                Button("Force Sleep") {
                    engine.setActivityState(.sleeping)
                }
                Button("System Reset") {
                    engine.resetToGenesis()
                    doubao.disconnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        doubao.connect()
                    }
                }
                Button("设置") {
                    showSettings = true
                }
            }
            .font(.caption2)
            .foregroundStyle(.white)
            ambientMoodSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var ambientMoodSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ambient Mood:")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
            Text("Current: \(engine.currentMood.rawValue)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 4) {
                ForEach(MobiMood.allCases, id: \.self) { mood in
                    Button(mood.rawValue.capitalized) { engine.setCurrentMood(mood) }
                }
            }
            .font(.caption2)
            .foregroundStyle(.white)
        }
    }

    private var liveEarSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Live Ear:")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
            Text(engine.currentTranscript.isEmpty ? (engine.activityState == .listening ? "(listening…)" : "(no input)") : engine.currentTranscript)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(3)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.black.opacity(0.6))
    }
}

// MARK: - T/E/S Sliders (observes psyche so sliders stay in sync when model updates)
private struct TESSlidersSectionView: View {
    @ObservedObject var psyche: UserPsycheModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("T/E/S (orb)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("W")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: Binding(get: { psyche.warmth }, set: { psyche.warmth = $0 }), in: 0...1)
                        .tint(.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("E")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: Binding(get: { psyche.energy }, set: { psyche.energy = $0 }), in: 0...1)
                        .tint(.yellow)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("S")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: Binding(get: { psyche.chaos }, set: { psyche.chaos = $0 }), in: 0...1)
                        .tint(.purple)
                }
            }
        }
    }
}
