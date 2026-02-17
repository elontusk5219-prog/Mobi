//
//  Day1IceBreakerState.swift
//  Mobi
//
//  Day 1 破冰状态持久化：按 userId 隔离。设计见 docs/故事与日常节律-设计与施工表.md §2.3。
//

import Foundation

enum Day1IceBreakerState {
    private static let hasCompletedPrefix = "Mobi.hasCompletedDay1IceBreaker."
    private static let userConfirmedAsStarPrefix = "Mobi.userConfirmedAsStar."

    /// 该用户是否已完成 Day 1 破冰（首次进 Room 时的「你是刚才那个声音吗？」等对话）。
    static func hasCompletedDay1IceBreaker(for userId: String) -> Bool {
        guard !userId.isEmpty else { return false }
        return UserDefaults.standard.bool(forKey: hasCompletedPrefix + userId)
    }

    /// 当前用户是否已完成 Day 1 破冰。
    static var currentUserHasCompletedDay1IceBreaker: Bool {
        hasCompletedDay1IceBreaker(for: UserIdentityService.currentUserId)
    }

    /// 标记该用户已完成 Day 1 破冰。
    static func markDay1IceBreakerCompleted(for userId: String) {
        guard !userId.isEmpty else { return }
        UserDefaults.standard.set(true, forKey: hasCompletedPrefix + userId)
    }

    /// 标记当前用户已完成 Day 1 破冰。
    static func markCurrentUserDay1IceBreakerCompleted() {
        markDay1IceBreakerCompleted(for: UserIdentityService.currentUserId)
    }

    /// 该用户是否已确认为 Star（命名仪式后）。
    static func userConfirmedAsStar(for userId: String) -> Bool {
        guard !userId.isEmpty else { return false }
        return UserDefaults.standard.bool(forKey: userConfirmedAsStarPrefix + userId)
    }

    /// 当前用户是否已确认为 Star。
    static var currentUserConfirmedAsStar: Bool {
        userConfirmedAsStar(for: UserIdentityService.currentUserId)
    }

    /// 标记该用户已确认为 Star。
    static func markUserConfirmedAsStar(for userId: String) {
        guard !userId.isEmpty else { return }
        UserDefaults.standard.set(true, forKey: userConfirmedAsStarPrefix + userId)
    }

    /// 标记当前用户已确认为 Star。
    static func markCurrentUserConfirmedAsStar() {
        markUserConfirmedAsStar(for: UserIdentityService.currentUserId)
    }
}
