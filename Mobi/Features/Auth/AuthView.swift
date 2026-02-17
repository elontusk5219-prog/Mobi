//
//  AuthView.swift
//  Mobi
//
//  登录门控：放在 Anima 之前。注册（输入用户名生成唯一账户）或登录（选择已有账户）后进入游戏。
//

import Combine
import SwiftUI

struct AuthView: View {
    @ObservedObject private var userIdentity = UserIdentityService.shared
    private let onSuccess: () -> Void

    @State private var registerUserName: String = ""
    @FocusState private var usernameFocused: Bool

    init(onSuccess: @escaping () -> Void) {
        self.onSuccess = onSuccess
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                registerSection
                if !userIdentity.registeredAccounts.isEmpty {
                    loginSection
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            userIdentity.logout()
            usernameFocused = userIdentity.registeredAccounts.isEmpty
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Mobi")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("每次启动请选择或输入要使用的 ID")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }

    private var registerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("注册新账户")
                .font(.headline)
            TextField("请输入用户名", text: $registerUserName)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($usernameFocused)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Button(action: doRegister) {
                Text("注册")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(registerUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用已有账户登录")
                .font(.headline)
            ForEach(userIdentity.registeredAccounts) { account in
                Button(action: { doLogin(account: account) }) {
                    HStack {
                        Text(account.userName?.isEmpty == false ? account.userName! : account.userId)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(account.userId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func doRegister() {
        let name = registerUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        userIdentity.generateNewUserId()
        userIdentity.setUserName(name)
        userIdentity.addRegisteredAccount(userId: UserIdentityService.currentUserId, userName: name)
        EvolutionManager.shared.reloadForCurrentUser()
        MobiEngine.shared.clearUserSpecificState()
        onSuccess()
    }

    private func doLogin(account: RegisteredAccount) {
        userIdentity.login(account: account)
        EvolutionManager.shared.reloadForCurrentUser()
        MobiEngine.shared.clearUserSpecificState()
        onSuccess()
    }
}
