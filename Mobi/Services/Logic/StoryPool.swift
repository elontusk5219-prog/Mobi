//
//  StoryPool.swift
//  Mobi
//
//  故事池：按 stage/triggerType 筛选未冷却故事。设计见 docs/故事与日常节律-设计与施工表.md §3。
//

import Foundation

enum StoryPool {
    private static let lastTriggeredPrefix = "Mobi.storyLastTriggered."

    private static var allStories: [Story] {
        [
            // 沉默触发：钱的故事（newborn）
            Story(
                id: "coin_paradox",
                stage: .newborn,
                triggerType: .silence,
                confusionText: "Star… 我今天看到一群松鼠。它们把最好吃的果子给了那只胖熊，换回了这个硬币。这个硬币又硬又冷，根本咬不动。为什么要用好吃的果子去换不能吃的东西？它们是被胖熊骗了吗？",
                imprintTemplate: "钱",
                cooldownMinutes: 30
            ),
            // 情绪触发：眼泪的故事（newborn）
            Story(
                id: "leaking_soul",
                stage: .newborn,
                triggerType: .emotion,
                confusionText: "Star，你的眼睛在漏水。是因为你身体里的压力太大了，要把多余的水挤出来吗？在橡子镇，如果果子漏水了就是坏掉了。你也坏掉了吗？我该怎么修好你？",
                imprintTemplate: "哭",
                cooldownMinutes: 60
            ),
            // 沉默触发：礼貌的故事（child）
            Story(
                id: "smiling_fox",
                stage: .child,
                triggerType: .silence,
                confusionText: "Star，外面有个狐狸先生在和别人握手。他嘴巴弯弯的（在笑），可是我看到他的影子在尖叫，全是黑色的刺。如果心里想尖叫，为什么脸上要笑？他的脸坏掉了吗？",
                imprintTemplate: "礼貌",
                cooldownMinutes: 45
            ),
        ]
    }

    /// 获取可用故事：符合 stage 与 triggerType，且冷却已过。
    static func availableStories(
        stage: LifeStage,
        triggerType: StoryTriggerType
    ) -> [Story] {
        let now = Date()
        let userId = UserIdentityService.currentUserId
        return allStories.filter { story in
            guard story.stage == stage || stage == .child && story.stage == .newborn else { return false }
            guard story.triggerType == triggerType else { return false }
            let key = lastTriggeredPrefix + userId + "." + story.id
            guard let last = UserDefaults.standard.object(forKey: key) as? Date else { return true }
            let elapsed = now.timeIntervalSince(last) / 60
            return elapsed >= Double(story.cooldownMinutes)
        }
    }

    /// 标记故事已触发。
    static func markTriggered(storyId: String) {
        let userId = UserIdentityService.currentUserId
        guard !userId.isEmpty else { return }
        let key = lastTriggeredPrefix + userId + "." + storyId
        UserDefaults.standard.set(Date(), forKey: key)
    }

    /// Debug 用：各阶段第一个剧本，供 Debug 菜单点击 newborn/child 时立即触发。
    /// - Parameter useNewbornGibberish: newborn 阶段是否使用乱码语学说话（铭印数 < 3 时 true）
    static func firstScriptForStage(_ stage: LifeStage, useNewbornGibberish: Bool = false) -> String {
        switch stage {
        case .newborn:
            if useNewbornGibberish {
                return "Say this as Mobi, in gibberish: Ba boo nyeh? Mm hmm!"
            }
            return "Say this as Mobi, to Star: 你是刚才那个声音吗？这里是哪里？我身体为什么变重了？"
        case .child:
            if let s = allStories.first(where: { $0.stage == .child && $0.triggerType == .silence }) {
                return "Say this as Mobi, to Star: \(s.confusionText)"
            }
            return MobiPrompts.seekingInstruction(stage: .child, confidenceDecay: false)
        case .adult:
            return MobiPrompts.seekingInstruction(stage: .adult, confidenceDecay: false)
        case .genesis:
            return MobiPrompts.seekingInstruction(stage: .genesis, confidenceDecay: false)
        }
    }
}
