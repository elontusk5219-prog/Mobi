//
//  Story.swift
//  Mobi
//
//  故事数据结构：困惑文本、触发类型、阶段、铭印模板。设计见 docs/故事与日常节律-设计与施工表.md §3。
//

import Foundation

enum StoryTriggerType: String, CaseIterable {
    case silence   // 沉默触发（替代 seeking）
    case emotion   // 用户情绪关键词触发
    case random    // 随机主动发起
}

struct Story: Identifiable {
    let id: String
    let stage: LifeStage
    let triggerType: StoryTriggerType
    let confusionText: String
    let imprintTemplate: String?
    let cooldownMinutes: Int
}
