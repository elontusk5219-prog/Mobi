//
//  MemoryDiaryService.swift
//  Mobi
//
//  Daily summary from Gemini (Backend). Placeholder until API is ready.
//  强模型 birth memories 可由此写入。
//

import Foundation

struct DiaryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let bullets: [String]
    let sentiment: DiarySentiment
}

enum DiarySentiment: String, CaseIterable {
    case sun
    case moon
    case heart
}

enum MemoryDiaryService {
    /// 强模型返回的出生记忆（来自 Anima transcript）。
    /// Anima 遗忘设定：birthMemories 不应以「Mobi 记得 Anima 对话」形式注入 Room prompt；仅作存储，不注入 roomSystemPrompt。
    private static func birthMemoriesKey(userId: String) -> String { "Mobi.\(userId).birthMemories" }

    static func addBirthMemories(_ memories: [SoulMemory]) {
        guard !memories.isEmpty else { return }
        let dicts = memories.map { ["summary": $0.summary, "importance": $0.importance] }
        UserDefaults.standard.set(dicts, forKey: birthMemoriesKey(userId: UserIdentityService.currentUserId))
    }

    /// 读取出生记忆。注意：按 Anima 遗忘设定，不得将结果注入 Room 的 roomSystemPrompt。
    static func getBirthMemories() -> [SoulMemory] {
        let key = birthMemoriesKey(userId: UserIdentityService.currentUserId)
        guard let arr = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else { return [] }
        return arr.compactMap { m -> SoulMemory? in
            guard let s = m["summary"] as? String, let imp = m["importance"] as? Double else { return nil }
            return SoulMemory(summary: s, importance: imp)
        }
    }

    /// Fetch yesterday's summary. 优先从 EverMemOS 检索；未配置或为空时回退 mock。
    static func fetchYesterdaySummary() async -> DiaryEntry {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let calendar = Calendar.current
        guard let dayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: yesterday),
              let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return mockDiaryEntry(date: yesterday)
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC") ?? .current
        let startTime = formatter.string(from: dayStart)
        let endTime = formatter.string(from: dayEnd)
        let items = await EverMemOSClient.shared.searchMemories(
            query: "总结昨天与用户的对话和互动",
            userId: EverMemOSMemoryService.currentUserId,
            groupId: EverMemOSMemoryService.currentGroupId,
            retrieveMethod: "hybrid",
            topK: 5,
            startTime: startTime,
            endTime: endTime
        )
        if items.isEmpty {
            return mockDiaryEntry(date: yesterday)
        }
        let bullets = items.prefix(5).compactMap { $0.summary ?? $0.content }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return DiaryEntry(
            date: yesterday,
            bullets: bullets.isEmpty ? ["暂无记录"] : bullets,
            sentiment: .heart
        )
    }

    private static func mockDiaryEntry(date: Date) -> DiaryEntry {
        DiaryEntry(
            date: date,
            bullets: [
                "你们聊到了今天的天气和心情。",
                "Mobi 表达了对新房间的喜爱。",
                "你们约定明天再见。"
            ],
            sentiment: .heart
        )
    }
}
