//
//  GuardianProtocolStore.swift
//  Mobi
//
//  Day 1 监护人协议：是否已签署（按用户）、请求麦克风与通知权限。
//

import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

enum GuardianProtocolStore {
    private static let keyPrefix = "Mobi.guardianProtocolCompleted."

    /// 该用户是否已完成监护人协议（已展示并处理过权限请求）。
    static func hasCompletedGuardianProtocol(userId: String) -> Bool {
        guard !userId.isEmpty else { return false }
        return UserDefaults.standard.bool(forKey: keyPrefix + userId)
    }

    /// 当前用户是否已完成监护人协议。
    static var currentUserHasCompletedGuardianProtocol: Bool {
        hasCompletedGuardianProtocol(userId: UserIdentityService.currentUserId)
    }

    /// 标记该用户已完成监护人协议（已展示过并完成权限请求流程，无论授权结果）。
    static func markGuardianProtocolCompleted(userId: String) {
        guard !userId.isEmpty else { return }
        UserDefaults.standard.set(true, forKey: keyPrefix + userId)
    }

    /// 请求麦克风与通知权限；完成后在主线程回调，true 表示两者均授权。
    static func requestMicAndNotificationPermission(completion: @escaping (Bool) -> Void) {
        #if os(iOS)
        let group = DispatchGroup()
        var micGranted = false
        var notificationGranted = false

        // 麦克风
        group.enter()
        DispatchQueue.main.async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
                try session.setActive(true)
            } catch {
                group.leave()
                return
            }
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    micGranted = granted
                    group.leave()
                }
            } else {
                session.requestRecordPermission { granted in
                    micGranted = granted
                    group.leave()
                }
            }
        }

        // 通知（在麦克风之后请求，避免同时弹两个系统框）
        group.enter()
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                notificationGranted = granted
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(micGranted && notificationGranted)
        }
        #else
        DispatchQueue.main.async { completion(true) }
        #endif
    }
}
