//
//  EnergyManager.swift
//  Mobi
//
//  精力值：按用户持久化；Room 内消耗（时间/对话轮次），IAP 或自然恢复补充。
//

import Combine
import Foundation

final class EnergyManager: ObservableObject {
    static let shared = EnergyManager()

    private static let keyPrefix = "Mobi.energy."
    private static let maxEnergy: Double = 100
    /// Room 内每经过此秒数扣减一次
    private static let consumeIntervalSeconds: TimeInterval = 60
    /// 每次时间扣减量
    private static let consumePerInterval: Double = 2
    /// 每完成一轮语音对话扣减
    private static let consumePerTurn: Double = 1

    @Published private(set) var currentEnergy: Double = 100
    private var lastConsumeTime: Date?
    private var lastKnownUserId: String = ""

    private init() {
        let userId = UserIdentityService.currentUserId
        lastKnownUserId = userId
        currentEnergy = Self.loadEnergy(userId: userId)
    }

    /// 是否已耗尽（≤0）
    var isDepleted: Bool { currentEnergy <= 0 }

    private static func key(userId: String) -> String {
        keyPrefix + userId
    }

    private static func loadEnergy(userId: String) -> Double {
        guard !userId.isEmpty else { return maxEnergy }
        let v = UserDefaults.standard.double(forKey: key(userId: userId))
        if v <= 0 { return maxEnergy }
        return min(v, maxEnergy)
    }

    private func persist() {
        let userId = UserIdentityService.currentUserId
        guard !userId.isEmpty else { return }
        UserDefaults.standard.set(currentEnergy, forKey: Self.key(userId: userId))
    }

    /// 切换用户后同步加载该用户精力（由调用方在登录/切换时调用）
    func syncCurrentUser() {
        let userId = UserIdentityService.currentUserId
        if userId != lastKnownUserId {
            lastKnownUserId = userId
            currentEnergy = Self.loadEnergy(userId: userId)
            lastConsumeTime = nil
        }
    }

    /// 消耗精力（Room 内按时间或按轮次调用）；不足时扣到 0。
    func consumeEnergy(amount: Double) {
        guard amount > 0 else { return }
        currentEnergy = max(0, currentEnergy - amount)
        persist()
    }

    /// 补充精力（IAP 或自然恢复后调用）
    func refillEnergy(amount: Double) {
        guard amount > 0 else { return }
        currentEnergy = min(Self.maxEnergy, currentEnergy + amount)
        persist()
    }

    /// 加满精力
    func refillToMax() {
        currentEnergy = Self.maxEnergy
        persist()
    }

    /// Room tick 调用：按经过时间扣减（每 N 秒扣一次）
    func tickConsumeIfNeeded(now: Date = Date()) {
        syncCurrentUser()
        guard currentEnergy > 0 else { return }
        let last = lastConsumeTime ?? now
        let elapsed = now.timeIntervalSince(last)
        if elapsed >= Self.consumeIntervalSeconds {
            let steps = Int(elapsed / Self.consumeIntervalSeconds)
            lastConsumeTime = last.addingTimeInterval(TimeInterval(steps) * Self.consumeIntervalSeconds)
            consumeEnergy(amount: Double(steps) * Self.consumePerInterval)
        }
    }

    /// 完成一轮语音对话时调用
    func consumeOneTurn() {
        syncCurrentUser()
        consumeEnergy(amount: Self.consumePerTurn)
    }
}
