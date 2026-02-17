//
//  SettingsView.swift
//  Mobi
//
//  设置界面：仅编辑当前用户 ID。
//

import Combine
import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject private var userIdentity = UserIdentityService.shared
    @ObservedObject private var evolution = EvolutionManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authGateBinding) private var authGateBinding

    @State private var editedUserId: String = ""
    @State private var editedUserName: String = ""
    @State private var showClearMemoriesConfirm = false
    @State private var clearMemoriesInProgress = false
    @State private var clearMemoriesMessage: String?
    @State private var copyGroupIdsMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("用户 ID", text: $editedUserId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("用户名（可选）", text: $editedUserName)
                    Button("生成新 ID") {
                        userIdentity.generateNewUserId()
                        editedUserId = UserIdentityService.currentUserId
                    }
                } header: {
                    Text("当前用户")
                } footer: {
                    Text("用户 ID 用于隔离 Anima 与 Mobi 数据。修改后将从该用户的数据加载。")
                }

                Section {
                    Text("已完成 Anima：\(UserIdentityService.currentUserHasCompletedAnima ? "是" : "否")")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("状态")
                }

                Section {
                    Button("清空云端记忆") {
                        showClearMemoriesConfirm = true
                    }
                    .disabled(clearMemoriesInProgress)
                    .foregroundStyle(clearMemoriesInProgress ? .secondary : .primary)
                    if let msg = clearMemoriesMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("复制已注册账户 Group ID 列表") {
                        copyRegisteredGroupIds()
                    }
                    if let msg = copyGroupIdsMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("记忆")
                } footer: {
                    Text("删除 EverMemOS 云端中当前用户的全部记忆。本地日记与画像不受影响。批量清空：先点「复制已注册账户 Group ID 列表」，在终端执行 pbpaste > Config/group_ids.txt 后运行 Config/clear-evermemos-all-users.sh Config/group_ids.txt。")
                }

                Section {
                    Button("切换账户", role: .destructive) {
                        dismiss()
                        userIdentity.logout()
                        authGateBinding?.wrappedValue = true
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedId = editedUserId.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedId.isEmpty {
                            userIdentity.setUserId(trimmedId)
                        }
                        userIdentity.setUserName(editedUserName.isEmpty ? nil : editedUserName)
                        evolution.reloadForCurrentUser()
                        dismiss()
                    }
                    .disabled(editedUserId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editedUserId = UserIdentityService.currentUserId
                editedUserName = userIdentity.currentUserName ?? ""
            }
            .alert("清空云端记忆", isPresented: $showClearMemoriesConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    performClearMemories()
                }
            } message: {
                Text("将删除 EverMemOS 云端中当前用户（\(EverMemOSMemoryService.currentGroupId)）下的全部记忆，不可恢复。确认继续？")
            }
        }
    }

    private func copyRegisteredGroupIds() {
        let prefix = "mobi_user_"
        let ids = userIdentity.registeredAccounts.map { "\(prefix)\($0.userId)" }
        guard !ids.isEmpty else {
            copyGroupIdsMessage = "当前无已注册账户"
            return
        }
        UIPasteboard.general.string = ids.joined(separator: "\n")
        copyGroupIdsMessage = "已复制 \(ids.count) 个 Group ID，可粘贴到 group_ids.txt 后运行清空脚本"
    }

    private func performClearMemories() {
        guard !clearMemoriesInProgress else { return }
        clearMemoriesInProgress = true
        clearMemoriesMessage = nil
        Task {
            let ok = await EverMemOSClient.shared.deleteMemories(groupId: EverMemOSMemoryService.currentGroupId)
            await MainActor.run {
                clearMemoriesInProgress = false
                clearMemoriesMessage = ok ? "已清空" : "清空失败，请检查 API 配置"
            }
        }
    }

}
