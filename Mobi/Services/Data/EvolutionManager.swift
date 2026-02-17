//
//  EvolutionManager.swift
//  Mobi
//
//  进化与人格槽：由画像 API 驱动（lifeStage、slotProgress、unlockedFeatures），只进不退；
//  未拉取到画像时降级为本地 state。约定见 docs/画像-进化接口契约.md、docs/Mobi用户画像与进化驱动设计.md。
//

import Foundation
import Combine
import SwiftUI

enum MobiFeature: String, Codable, CaseIterable {
    case colorShift
    case coffeeCup
}

struct UserEvolutionState: Codable {
    var interactionCount: Int = 0
    var intimacyLevel: Int = 0
    var unlockedFeatures: [String] = []
    var keywordMentions: [String: Int] = [:]

    static func storageKey(userId: String) -> String { "mobi.\(userId).userEvolutionState" }
}

/// 上次成功应用的画像结果缓存；用于只进不退与离线展示。
private struct CachedEvolutionProfile: Codable {
    var lifeStageRaw: String
    var slotProgress: Double
    var unlockedFeatures: [String]
    var confidenceDecay: Bool
    var languageHabits: String?

    static func storageKey(userId: String) -> String { "mobi.\(userId).evolutionProfileCache" }

    func parsedStage() -> LifeStage {
        switch lifeStageRaw.lowercased() {
        case "child": return .child
        case "adult": return .adult
        default: return .newborn
        }
    }
}

@MainActor
final class EvolutionManager: ObservableObject {
    static let shared = EvolutionManager()

    @Published private(set) var experiencePoints: Int = 0
    /// 进化阶段：有画像缓存时以缓存为准，否则为 setStage/forceEvolve 设定值（如 triggerBirth 的 newborn）。
    @Published private(set) var currentStage: LifeStage = .genesis
    @Published private(set) var state: UserEvolutionState = UserEvolutionState()

    /// 是否处于置信度衰减（画像返回）；为 true 时行为/对话可触发「拿不准你」类表现，阶段不变。
    @Published private(set) var confidenceDecay: Bool = false

    /// Soul Vessel 是否已满溢并完成炸裂序列（只进不退）；为 true 时仅展示胸口印记，不再展示瓶身。
    @Published private(set) var vesselHasOverflowed: Bool = false

    /// 用户语言习惯描述，画像 API 返回时注入 Room 对话；nil 则不注入。
    var languageHabits: String? { cachedProfile?.languageHabits }

    private var cachedProfile: CachedEvolutionProfile?
    private static func vesselHasOverflowedKey(userId: String) -> String { "mobi.\(userId).vesselHasOverflowed" }
    private let triggerColorShiftThreshold = 80
    private let triggerCoffeeMentions = 3
    private let coffeeKeyword = "咖啡"

    init() {
        loadState()
        loadCachedProfile()
        loadVesselOverflowed()
        applyCachedStageIfNeeded()
    }

    /// 用户 ID 变更后调用，重载当前用户数据。
    func reloadForCurrentUser() {
        loadState()
        loadCachedProfile()
        loadVesselOverflowed()
        applyCachedStageIfNeeded()
        objectWillChange.send()
    }

    private var currentUserId: String { UserIdentityService.currentUserId }

    // MARK: - 画像驱动（只进不退）

    /// Room 内展示用的进化阶段：有缓存用缓存，否则用 currentStage（如 newborn）。
    var effectiveStage: LifeStage {
        if let c = cachedProfile { return c.parsedStage() }
        return currentStage
    }

    /// 人格槽进度 0.0–1.0：有缓存用缓存，否则降级为 interactionCount/10。
    var personalitySlotProgress: Double {
        if let c = cachedProfile { return min(1.0, max(0, c.slotProgress)) }
        return min(1.0, Double(state.interactionCount) / 10.0)
    }

    /// 拉取画像并应用（只进不退）；建议在 Room onAppear 调用。
    func fetchAndApplyProfile() async {
        let response = await EvolutionProfileService.shared.fetch()
        applyProfileResponse(response)
    }

    /// 应用画像响应：仅当服务端阶段 ≥ 本地阶段时更新，并持久化缓存。未返回有效 lifeStage 时用 completeness 与阈值 A/B 推导（P1-2）。
    func applyProfileResponse(_ response: EvolutionProfileResponse) {
        let lifeStageEffective: String
        let serverStage: LifeStage
        if response.lifeStage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let derived = response.derivedLifeStageFromCompleteness() {
            serverStage = derived
            lifeStageEffective = derived.rawValue
        } else {
            serverStage = response.parsedLifeStage()
            lifeStageEffective = response.lifeStage
        }
        let order = serverStage.evolutionOrder
        let currentOrder = (cachedProfile?.parsedStage() ?? currentStage).evolutionOrder
        guard order >= currentOrder else { return }
        cachedProfile = CachedEvolutionProfile(
            lifeStageRaw: lifeStageEffective,
            slotProgress: response.slotProgress,
            unlockedFeatures: response.unlockedFeatures ?? cachedProfile?.unlockedFeatures ?? [],
            confidenceDecay: response.confidenceDecay ?? false,
            languageHabits: response.languageHabits ?? cachedProfile?.languageHabits
        )
        confidenceDecay = cachedProfile!.confidenceDecay
        persistCachedProfile()
        currentStage = cachedProfile!.parsedStage()
        objectWillChange.send()
    }

    // MARK: - 本地状态与兼容

    func gainXP(amount: Int) {
        experiencePoints += amount
    }

    func forceEvolve(targetStage: LifeStage) {
        currentStage = targetStage
        if targetStage == .genesis {
            cachedProfile = nil
            UserDefaults.standard.removeObject(forKey: CachedEvolutionProfile.storageKey(userId: currentUserId))
            vesselHasOverflowed = false
            UserDefaults.standard.removeObject(forKey: Self.vesselHasOverflowedKey(userId: currentUserId))
        } else if var c = cachedProfile {
            // Debug 跳阶段：effectiveStage 优先用缓存，需同步更新缓存否则界面不会变。
            c.lifeStageRaw = targetStage.rawValue
            cachedProfile = c
            persistCachedProfile()
        }
        objectWillChange.send()
    }

    /// 在 Soul Vessel 满溢动画（裂纹→炸裂→光芒融入）结束后调用；只进不退。
    func markVesselOverflowed() {
        guard !vesselHasOverflowed else { return }
        vesselHasOverflowed = true
        UserDefaults.standard.set(true, forKey: Self.vesselHasOverflowedKey(userId: currentUserId))
        objectWillChange.send()
    }

    func setStage(_ stage: LifeStage) {
        currentStage = stage
    }

    /// 每轮 Room 对话结束时调用；仍用于本地 fallback 与上报。
    func recordRoomInteraction() {
        state.interactionCount += 1
        if state.interactionCount % 10 == 0 {
            state.intimacyLevel = min(100, state.intimacyLevel + 5)
        }
        evaluateTriggers()
        persistState()
        objectWillChange.send()
    }

    func updateIntimacy(_ level: Int) {
        state.intimacyLevel = min(100, max(0, level))
        evaluateTriggers()
        persistState()
        objectWillChange.send()
    }

    func scanAndRecordKeywords(in text: String) {
        if text.contains(coffeeKeyword) {
            state.keywordMentions[coffeeKeyword, default: 0] += 1
            evaluateTriggers()
            persistState()
            objectWillChange.send()
        }
    }

    /// 是否已解锁某进化外观：有画像缓存且含列表时以缓存为准，否则用本地 state。
    func hasUnlocked(_ feature: MobiFeature) -> Bool {
        if let c = cachedProfile, !c.unlockedFeatures.isEmpty {
            return c.unlockedFeatures.contains(feature.rawValue)
        }
        return state.unlockedFeatures.contains(feature.rawValue)
    }

    // MARK: - 私有

    private func evaluateTriggers() {
        var changed = false
        if state.intimacyLevel >= triggerColorShiftThreshold, !state.unlockedFeatures.contains(MobiFeature.colorShift.rawValue) {
            state.unlockedFeatures.append(MobiFeature.colorShift.rawValue)
            changed = true
        }
        if (state.keywordMentions[coffeeKeyword] ?? 0) >= triggerCoffeeMentions, !state.unlockedFeatures.contains(MobiFeature.coffeeCup.rawValue) {
            state.unlockedFeatures.append(MobiFeature.coffeeCup.rawValue)
            changed = true
        }
        if changed { objectWillChange.send() }
    }

    private func applyCachedStageIfNeeded() {
        if let c = cachedProfile {
            currentStage = c.parsedStage()
            confidenceDecay = c.confidenceDecay
        }
    }

    private func persistState() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: UserEvolutionState.storageKey(userId: currentUserId))
        }
    }

    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: UserEvolutionState.storageKey(userId: currentUserId)),
              let decoded = try? JSONDecoder().decode(UserEvolutionState.self, from: data) else { return }
        state = decoded
    }

    private func persistCachedProfile() {
        guard let c = cachedProfile, let data = try? JSONEncoder().encode(c) else { return }
        UserDefaults.standard.set(data, forKey: CachedEvolutionProfile.storageKey(userId: currentUserId))
    }

    private func loadCachedProfile() {
        guard let data = UserDefaults.standard.data(forKey: CachedEvolutionProfile.storageKey(userId: currentUserId)),
              let decoded = try? JSONDecoder().decode(CachedEvolutionProfile.self, from: data) else { return }
        cachedProfile = decoded
    }

    private func loadVesselOverflowed() {
        vesselHasOverflowed = UserDefaults.standard.bool(forKey: Self.vesselHasOverflowedKey(userId: currentUserId))
    }
}
