//
//  BehaviorReportingService.swift
//  Mobi
//
//  Room 内行为事件上报，按方案 A 写入 EverMemOS（sender=mobi_behavior）。
//  画像服务按 sender 过滤，与对话记忆分开处理。契约见 docs/行为上报与画像输入.md。
//

import Foundation

enum BehaviorEvent {
    case poke
    case drag
    case longPress
    case vesselTap
    case vesselLongPress
    case silenceInterval(durationSeconds: Int)
    case sessionStart
    case sessionEnd
}

final class BehaviorReportingService {
    static let shared = BehaviorReportingService()

    private static let senderId = "mobi_behavior"
    private var lastPokeTime: Date?
    private let pokeThrottleSeconds: TimeInterval = 1.0

    private init() {}

    /// 记录行为事件；poke 有 1s 节流。
    func record(event: BehaviorEvent, sessionId: String? = nil) {
        let ts = Int64(Date().timeIntervalSince1970 * 1000)
        switch event {
        case .poke:
            if let last = lastPokeTime, Date().timeIntervalSince(last) < pokeThrottleSeconds { return }
            lastPokeTime = Date()
        default:
            break
        }
        let eventName = eventNameFor(event)
        var content: [String: Any] = [
            "type": "behavior",
            "event": eventName,
            "ts": ts
        ]
        if let sid = sessionId { content["session_id"] = sid }
        if case .silenceInterval(let sec) = event { content["duration_seconds"] = sec }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: content),
              let contentStr = String(data: jsonData, encoding: .utf8) else { return }
        let messageId = "behavior_\(EverMemOSMemoryService.currentUserId)_\(eventName)_\(ts)"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC") ?? .current
        let request = EverMemOSStoreRequest(
            message_id: messageId,
            create_time: formatter.string(from: Date()),
            sender: Self.senderId,
            content: contentStr,
            role: "behavior",
            sender_name: nil,
            user_id: EverMemOSMemoryService.currentUserId,
            group_id: EverMemOSMemoryService.currentGroupId,
            group_name: "Mobi Room",
            refer_list: nil
        )
        Task { _ = await EverMemOSClient.shared.storeMemory(request) }
    }

    private func eventNameFor(_ event: BehaviorEvent) -> String {
        switch event {
        case .poke: return "poke"
        case .drag: return "drag"
        case .longPress: return "long_press"
        case .vesselTap: return "vessel_tap"
        case .vesselLongPress: return "vessel_long_press"
        case .silenceInterval: return "silence_interval"
        case .sessionStart: return "session_start"
        case .sessionEnd: return "session_end"
        }
    }
}
