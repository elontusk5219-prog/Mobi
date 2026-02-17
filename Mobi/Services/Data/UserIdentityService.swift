//
//  UserIdentityService.swift
//  Mobi
//
//  用户身份中心：当前用户 ID、用户名、已注册账户列表、Anima 完成标记。
//  登录门控在 Anima 之前：未登录时显示注册/登录页，登录后生成或选择唯一账户进入游戏。
//

import Combine
import Foundation

/// 已注册账户（用于登录列表）
struct RegisteredAccount: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    var userName: String?
}

final class UserIdentityService: ObservableObject {
    static let shared = UserIdentityService()

    private static let userIdKey = "Mobi.currentUserId"
    private static let userNameKey = "Mobi.currentUserName"
    private static let hasCompletedAnimaPrefix = "Mobi.hasCompletedAnima."
    private static let registeredAccountsKey = "Mobi.registeredAccounts"

    /// 向后兼容：旧版使用 Mobi.everMemOSUserId
    private static let legacyUserIdKey = "Mobi.everMemOSUserId"

    /// 当前用户 ID；未登录时返回空字符串（不自动生成，需先注册/登录）。
    static var currentUserId: String {
        if let existing = UserDefaults.standard.string(forKey: userIdKey), !existing.isEmpty {
            return existing
        }
        if let legacy = UserDefaults.standard.string(forKey: legacyUserIdKey), !legacy.isEmpty {
            UserDefaults.standard.set(legacy, forKey: userIdKey)
            UserDefaults.standard.removeObject(forKey: legacyUserIdKey)
            return legacy
        }
        return ""
    }

    @Published private(set) var publishedUserId: String
    @Published var currentUserName: String?
    @Published private(set) var registeredAccounts: [RegisteredAccount] = []

    private init() {
        publishedUserId = Self.currentUserId
        currentUserName = UserDefaults.standard.string(forKey: Self.userNameKey)
        loadRegisteredAccounts()
        migrateCurrentUserToRegisteredIfNeeded()
    }

    /// 供 SwiftUI 绑定使用
    var currentUserId: String { Self.currentUserId }

    /// 设置当前用户 ID；编辑后需调用方重载该用户数据。
    func setUserId(_ id: String) {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != Self.currentUserId else { return }
        UserDefaults.standard.set(trimmed, forKey: Self.userIdKey)
        DispatchQueue.main.async { [weak self] in
            self?.publishedUserId = trimmed
            self?.currentUserName = UserDefaults.standard.string(forKey: Self.userNameKey)
            self?.objectWillChange.send()
        }
    }

    func setUserName(_ name: String?) {
        currentUserName = name
        if let n = name {
            UserDefaults.standard.set(n, forKey: Self.userNameKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.userNameKey)
        }
        objectWillChange.send()
    }

    /// 生成新 ID 并应用（不自动加入已注册列表，注册流程里会调用 addRegisteredAccount）。
    func generateNewUserId() {
        let id = "user_\(UUID().uuidString.prefix(8))"
        UserDefaults.standard.set(id, forKey: Self.userIdKey)
        DispatchQueue.main.async { [weak self] in
            self?.publishedUserId = id
            self?.objectWillChange.send()
        }
    }

    /// 将当前 (userId, userName) 加入已注册列表，供登录时选择。
    func addRegisteredAccount(userId: String, userName: String?) {
        var list = registeredAccounts
        if !list.contains(where: { $0.userId == userId }) {
            list.append(RegisteredAccount(userId: userId, userName: userName))
            registeredAccounts = list
            persistRegisteredAccounts()
        }
    }

    /// 退出登录：清空当前用户，下次启动或需重新登录/注册。
    func logout() {
        UserDefaults.standard.removeObject(forKey: Self.userIdKey)
        UserDefaults.standard.removeObject(forKey: Self.userNameKey)
        publishedUserId = ""
        currentUserName = nil
        objectWillChange.send()
    }

    /// 使用指定账户登录（设为当前用户）。
    func login(account: RegisteredAccount) {
        UserDefaults.standard.set(account.userId, forKey: Self.userIdKey)
        if let name = account.userName {
            UserDefaults.standard.set(name, forKey: Self.userNameKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.userNameKey)
        }
        publishedUserId = account.userId
        currentUserName = account.userName
        objectWillChange.send()
    }

    private func loadRegisteredAccounts() {
        guard let data = UserDefaults.standard.data(forKey: Self.registeredAccountsKey),
              let decoded = try? JSONDecoder().decode([RegisteredAccount].self, from: data) else { return }
        registeredAccounts = decoded
    }

    private func persistRegisteredAccounts() {
        guard let data = try? JSONEncoder().encode(registeredAccounts) else { return }
        UserDefaults.standard.set(data, forKey: Self.registeredAccountsKey)
    }

    /// 兼容旧版：若已有 currentUserId 但从未加入过列表，则自动加入一条。
    private func migrateCurrentUserToRegisteredIfNeeded() {
        let id = Self.currentUserId
        guard !id.isEmpty, !registeredAccounts.contains(where: { $0.userId == id }) else { return }
        let name = UserDefaults.standard.string(forKey: Self.userNameKey)
        registeredAccounts.append(RegisteredAccount(userId: id, userName: name))
        persistRegisteredAccounts()
    }

    /// 该用户是否已完成 Anima（进入过 Room）。
    static func hasCompletedAnima(for userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: hasCompletedAnimaPrefix + userId)
    }

    /// 标记该用户已完成 Anima。
    static func markAnimaCompleted(for userId: String) {
        UserDefaults.standard.set(true, forKey: hasCompletedAnimaPrefix + userId)
    }

    /// 当前用户是否已完成 Anima。
    static var currentUserHasCompletedAnima: Bool {
        hasCompletedAnima(for: currentUserId)
    }
}
