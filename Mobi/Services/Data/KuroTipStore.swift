//
//  KuroTipStore.swift
//  Mobi
//
//  Kuro 机制介绍轻量提示：按用户 + tipKey 记录是否已展示，每类只展示一次。
//

import Foundation

/// 机制介绍提示类型，对应不同触发情境
enum KuroTipKey: String, CaseIterable, Identifiable {
    case soulVessel   // 首次长按灵器并关闭 Soul Sync 后
    case seeking      // 首次触发 Seeking 后
    case diary        // 首次打开并关闭记忆日记后
    case energyLow    // 精力首次低于阈值时
    case goodnight    // 首次 22 点后进房晚安 drawing 时

    var id: String { rawValue }
}

enum KuroTipStore {
    private static let keyPrefix = "Mobi.kuroTipShown."

    private static func key(userId: String, tipKey: KuroTipKey) -> String {
        keyPrefix + userId + "." + tipKey.rawValue
    }

    /// 该用户是否已展示过该类型提示
    static func hasShown(userId: String, tipKey: KuroTipKey) -> Bool {
        guard !userId.isEmpty else { return false }
        return UserDefaults.standard.bool(forKey: key(userId: userId, tipKey: tipKey))
    }

    /// 当前用户是否已展示过该类型提示
    static func currentUserHasShown(_ tipKey: KuroTipKey) -> Bool {
        hasShown(userId: UserIdentityService.currentUserId, tipKey: tipKey)
    }

    /// 标记该用户已展示过该类型提示
    static func markShown(userId: String, tipKey: KuroTipKey) {
        guard !userId.isEmpty else { return }
        UserDefaults.standard.set(true, forKey: key(userId: userId, tipKey: tipKey))
    }

    /// 标记当前用户已展示
    static func markCurrentUserShown(_ tipKey: KuroTipKey) {
        markShown(userId: UserIdentityService.currentUserId, tipKey: tipKey)
    }
}
