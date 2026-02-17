//
//  ImprintService.swift
//  Mobi
//
//  铭印存储：从 Mobi 回复中识别「原来…」「我懂了…」「Star 教会了我…」并写入 UserDefaults。设计见 docs/故事与日常节律-设计与施工表.md §3。
//

import Foundation

struct ImprintRecord: Codable {
    let content: String
    let storyId: String?
    let timestamp: Date
}

enum ImprintService {
    private static let storagePrefix = "Mobi.imprints."
    private static let maxRecordsPerUser = 50

    private static func storageKey(userId: String) -> String {
        "\(storagePrefix)\(userId)"
    }

    /// 从 Mobi 回复中识别铭印（如「原来…」「我懂了…」「Star 教会了我…」），提取后写入。
    static func tryExtractAndStore(from mobiReply: String, storyId: String? = nil) {
        let trimmed = mobiReply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let lower = trimmed.lowercased()
        guard lower.contains("原来") || lower.contains("我懂了") || lower.contains("懂了") || lower.contains("教会了我") || lower.contains("教会了") else { return }
        let userId = UserIdentityService.currentUserId
        guard !userId.isEmpty else { return }
        let content = trimmed.prefix(200).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        let record = ImprintRecord(content: content, storyId: storyId, timestamp: Date())
        var list = getImprints(for: userId)
        list.insert(record, at: 0)
        if list.count > maxRecordsPerUser { list = Array(list.prefix(maxRecordsPerUser)) }
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: storageKey(userId: userId))
    }

    /// 获取该用户的铭印列表（按时间倒序）。
    static func getImprints(for userId: String) -> [ImprintRecord] {
        guard !userId.isEmpty else { return [] }
        guard let data = UserDefaults.standard.data(forKey: storageKey(userId: userId)),
              let list = try? JSONDecoder().decode([ImprintRecord].self, from: data) else { return [] }
        return list
    }

    /// 获取当前用户的铭印列表。
    static func getCurrentUserImprints() -> [ImprintRecord] {
        getImprints(for: UserIdentityService.currentUserId)
    }

    /// 学说话「教会」时刻：用户重复同一词 2–3 次后，程序化写入铭印（如「水」）。设计见 newborn 学说话上瘾计划。
    static func storeLearnedWord(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userId = UserIdentityService.currentUserId
        guard !userId.isEmpty else { return }
        let record = ImprintRecord(content: trimmed, storyId: nil, timestamp: Date())
        var list = getImprints(for: userId)
        list.insert(record, at: 0)
        if list.count > maxRecordsPerUser { list = Array(list.prefix(maxRecordsPerUser)) }
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: storageKey(userId: userId))
    }
}
