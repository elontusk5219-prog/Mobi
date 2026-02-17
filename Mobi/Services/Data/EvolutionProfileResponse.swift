//
//  EvolutionProfileResponse.swift
//  Mobi
//
//  画像 API 进化/人格槽响应模型。约定见 docs/画像-进化接口契约.md。
//

import Foundation

/// 画像服务返回的进化与人格槽数据；用于 EvolutionManager 只进不退与人格槽展示。
struct EvolutionProfileResponse: Codable {
    /// 进化阶段：newborn | child | adult。只进不退，由服务端保证。
    let lifeStage: String
    /// 人格槽整体进度 0.0–1.0，驱动 7 格填充。
    let slotProgress: Double
    /// 画像完整度 0.0–1.0，可选；可用于调试或 UI。
    let completeness: Double?
    /// 各维度置信度，可选；键可与 Big Five 对齐。
    let dimensionConfidences: [String: Double]?
    /// 是否处于置信度衰减（如长期未互动）；为 true 时可触发「拿不准你」类话术，阶段不变。
    let confidenceDecay: Bool?
    /// 已解锁的进化外观，如 ["colorShift","coffeeCup"]；若服务端不维护可由客户端按阶段推导。
    let unlockedFeatures: [String]?
    /// 用户语言习惯描述，供 Room 对话注入；画像服务扩展后返回，见 docs/语言习惯管道-画像侧.md。
    let languageHabits: String?

    enum CodingKeys: String, CodingKey {
        case lifeStage
        case slotProgress
        case completeness
        case dimensionConfidences
        case confidenceDecay
        case unlockedFeatures
        case languageHabits = "language_habits"
    }

    /// 将 lifeStage 字符串解析为 LifeStage 枚举；无效或 genesis 时返回 newborn（Room 内不应出现 genesis）。
    func parsedLifeStage() -> LifeStage {
        switch lifeStage.lowercased() {
        case "child": return .child
        case "adult": return .adult
        case "newborn", "genesis", _: return .newborn
        }
    }

    /// 当 API 未返回有效 lifeStage 时，用完整度与阈值 A/B 推导阶段（P1-2）。阈值 A=0.5 幼年→青年，B=0.8 青年→成年。
    func derivedLifeStageFromCompleteness(thresholdA: Double = 0.5, thresholdB: Double = 0.8) -> LifeStage? {
        guard let c = completeness else { return nil }
        if c >= thresholdB { return .adult }
        if c >= thresholdA { return .child }
        return .newborn
    }
}

// MARK: - LifeStage 只进不退顺序

extension LifeStage {
    /// 用于只进不退比较：数值越大阶段越晚。仅比较 Room 内阶段（newborn / child / adult）。
    var evolutionOrder: Int {
        switch self {
        case .genesis: return -1
        case .newborn: return 0
        case .child: return 1
        case .adult: return 2
        }
    }

    /// 仅当 other 的阶段不早于 self 时返回 true（可用于只进不退判断）。
    func isNotAfter(_ other: LifeStage) -> Bool {
        evolutionOrder <= other.evolutionOrder
    }
}
