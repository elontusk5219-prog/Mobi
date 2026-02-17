//
//  NewbornSpeechState.swift
//  Mobi
//
//  newborn 学说话状态：首次听到用户说话后从 mute 过渡到 gibberish。设计见 newborn 学说话上瘾计划。
//

import Foundation

enum NewbornSpeechState {
    private static let hasHeardUserSpeechPrefix = "Mobi.newbornHasHeardUserSpeech."

    /// 该用户 newborn 阶段是否已听过用户说话（用于 mute→gibberish 过渡）
    static func hasHeardUserSpeech(for userId: String) -> Bool {
        guard !userId.isEmpty else { return false }
        return UserDefaults.standard.bool(forKey: hasHeardUserSpeechPrefix + userId)
    }

    /// 当前用户 newborn 是否已听过用户说话
    static var currentUserHasHeardUserSpeech: Bool {
        hasHeardUserSpeech(for: UserIdentityService.currentUserId)
    }

    /// 标记该用户 newborn 已听过用户说话
    static func markHeardUserSpeech(for userId: String) {
        guard !userId.isEmpty else { return }
        UserDefaults.standard.set(true, forKey: hasHeardUserSpeechPrefix + userId)
    }

    /// 标记当前用户 newborn 已听过用户说话
    static func markCurrentUserHeardUserSpeech() {
        markHeardUserSpeech(for: UserIdentityService.currentUserId)
    }
}
