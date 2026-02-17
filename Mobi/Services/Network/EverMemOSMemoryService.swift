//
//  EverMemOSMemoryService.swift
//  Mobi
//
//  Room 阶段记忆业务封装：存储对话轮、检索记忆、转 prompt 片段。
//  遵守 Anima 遗忘：仅管理 Mobi 出生后的 Room 对话，不涉及 Anima transcript。
//

import Foundation

enum EverMemOSMemoryService {
    private static let groupIdPrefix = "mobi_user_"
    private static let assistantSenderId = "mobi_assistant"

    /// 设备/用户 ID；委托给 UserIdentityService
    static var currentUserId: String { UserIdentityService.currentUserId }

    static var currentGroupId: String {
        "\(groupIdPrefix)\(currentUserId)"
    }

    /// 暂存最近一次用户发言，用于 onChatContent 时成对存储
    private static var _lastUserUtterance: (text: String, time: Date)?
    private static let lock = NSLock()

    /// 用户说完时调用，更新 lastUserUtterance
    static func recordUserUtterance(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }
        _lastUserUtterance = (trimmed, Date())
    }

    /// AI 回复完整时调用；若有 lastUserUtterance 则存储 user+assistant 两条，然后清空
    static func storeTurnIfComplete(assistantContent: String) {
        let clean = stripMetadata(from: assistantContent)
        guard !clean.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        lock.lock()
        let userData = _lastUserUtterance
        _lastUserUtterance = nil
        lock.unlock()

        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC") ?? .current
        let timestamp = formatter.string(from: now)

        if let user = userData {
            let userMsgId = "msg_u_\(UUID().uuidString.prefix(8))"
            let assistantMsgId = "msg_a_\(UUID().uuidString.prefix(8))"
            Task {
                _ = await EverMemOSClient.shared.storeMemory(EverMemOSStoreRequest(
                    message_id: userMsgId,
                    create_time: formatter.string(from: user.time),
                    sender: currentUserId,
                    content: user.text,
                    role: "user",
                    sender_name: nil,
                    user_id: currentUserId,
                    group_id: currentGroupId,
                    group_name: "Mobi Room",
                    refer_list: nil
                ))
                _ = await EverMemOSClient.shared.storeMemory(EverMemOSStoreRequest(
                    message_id: assistantMsgId,
                    create_time: timestamp,
                    sender: assistantSenderId,
                    content: clean,
                    role: "assistant",
                    sender_name: "Mobi",
                    user_id: currentUserId,
                    group_id: currentGroupId,
                    group_name: "Mobi Room",
                    refer_list: [userMsgId]
                ))
            }
        }
    }

    /// 剥离 [METADATA: ...] 与 [v: ...] 等标记
    private static func stripMetadata(from text: String) -> String {
        var result = text
        if let idx = result.firstIndex(of: "["),
           result[idx...].hasPrefix("[METADATA") || result[idx...].hasPrefix("[v:") {
            result = String(result[..<idx])
        }
        if let idx = result.range(of: "METADATA_UPDATE:")?.lowerBound {
            result = String(result[..<idx])
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Session 启动前调用，检索记忆并转为自然语言片段。
    /// 各阶段均检索；newborn 用较少条数（limit 4）体现「刚出生没那么聪明」，child/adult 用默认 8 条。
    static func fetchMemoriesForSession(stage: LifeStage, limit: Int = 8) async -> String {
        let topK = stage == .newborn ? min(4, limit) : limit
        let items = await EverMemOSClient.shared.searchMemories(
            query: "与用户的对话、用户说过的话、用户的偏好和经历",
            userId: currentUserId,
            groupId: currentGroupId,
            retrieveMethod: "hybrid",
            topK: topK
        )
        guard !items.isEmpty else { return "" }
        let bullets = items.prefix(topK).compactMap { item -> String? in
            let s = item.summary ?? item.content
            return s?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard !bullets.isEmpty else { return "" }
        return "你记得：\(bullets.joined(separator: "；"))"
    }
}
