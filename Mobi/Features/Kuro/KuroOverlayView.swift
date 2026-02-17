//
//  KuroOverlayView.swift
//  Mobi
//
//  Kuro 出面时的全屏/半屏 overlay：压暗背景 + 气泡文案 + 可选确认/取消按钮。
//

import SwiftUI

enum KuroOverlayMode {
    /// 行政：设置 / 重置
    case admin(onSettings: () -> Void, onReset: () -> Void)
    /// 监护人协议：多步文案；同意后执行 requestPermissions(completion:)，再展示结果文案与关闭
    case guardian(onRequestPermissions: (@escaping (Bool) -> Void) -> Void, onClose: (Bool) -> Void)
    /// 开场介绍（星露谷风格）：3 屏介绍 + 第 3 屏权限请求；同意→请求权限→关闭；稍后→关闭且麦克风不开
    case welcomeIntro(onRequestPermissions: (@escaping (Bool) -> Void) -> Void, onClose: (Bool) -> Void)
    /// 进化考核：进化许可按钮后关闭并回调
    case evolution(onPermit: () -> Void)
    /// 能量账单：购买入口；onPurchase 异步完成后通过 completion(Bool) 回传成功则展示「交易愉快」与关闭
    case energy(onPurchase: (@escaping (Bool) -> Void) -> Void, onDismiss: () -> Void)
}

struct KuroOverlayView: View {
    let mode: KuroOverlayMode
    @Environment(\.dismiss) private var dismiss

    @State private var guardianStep = 0
    @State private var guardianResult: Bool? = nil  // 同意并请求权限后的结果，nil 表示未到结果步
    @State private var welcomeIntroStep = 0  // 0/1/2 对应三屏
    @State private var showResetConfirm = false
    @State private var energyPurchaseSuccess = false  // 能量购买成功后展示「交易愉快」

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 24) {
                KuroCharacterView(
                    accessory: kuroAccessoryForMode,
                    scale: 1.2
                )

                speechBubble

                if actionButtonsVisible {
                    actionButtons
                }
            }
            .padding(32)
        }
        .alert(KuroScripts.adminResetConfirmTitle, isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) {}
            Button("销毁", role: .destructive) {
                performReset()
            }
        } message: {
            Text(KuroScripts.adminResetConfirmMessage)
        }
        .onDisappear { KuroVoiceSynthesizer.shared.stop() }
    }

    private var kuroAccessoryForMode: KuroAccessory? {
        switch mode {
        case .admin: return nil
        case .guardian: return nil
        case .welcomeIntro: return nil
        case .evolution: return .clipboard
        case .energy: return .bill
        }
    }

    private var isGuardianMultiStep: Bool {
        if case .guardian = mode { return true }
        return false
    }

    /// 是否显示操作按钮：行政/进化/能量始终显示；监护人未到结果步时在 step>=2 显示同意/拒绝，结果步显示关闭；welcomeIntro 每屏都显示
    private var actionButtonsVisible: Bool {
        switch mode {
        case .admin, .evolution, .energy: return true
        case .guardian: return guardianResult != nil || guardianStep >= 2
        case .welcomeIntro: return true
        }
    }

    private var currentScriptKey: String {
        switch mode {
        case .admin: return "adminGreeting"
        case .guardian:
            if let result = guardianResult { return result ? "guardianSuccess" : "guardianPartialOrDeclined" }
            switch guardianStep {
            case 0: return "guardianLine1"
            case 1: return "guardianMobiReply"
            default: return "guardianLine2"
            }
        case .welcomeIntro: return "welcomeIntro_\(welcomeIntroStep)"
        case .evolution: return "evolutionScan"
        case .energy: return energyPurchaseSuccess ? "energyBillSuccess" : "energyBillWarning"
        }
    }

    private var speechBubble: some View {
        VStack(spacing: 8) {
            Text(KuroGibberishGenerator.gibberish(for: currentScriptKey))
                .font(.body)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(currentScriptLine)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            if let subtitle = scriptSubtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: 320)
        .onAppear { KuroVoiceSynthesizer.shared.speak(KuroGibberishGenerator.gibberish(for: currentScriptKey)) }
        .onChange(of: guardianStep) { _, _ in KuroVoiceSynthesizer.shared.speak(KuroGibberishGenerator.gibberish(for: currentScriptKey)) }
        .onChange(of: guardianResult) { _, _ in KuroVoiceSynthesizer.shared.speak(KuroGibberishGenerator.gibberish(for: currentScriptKey)) }
        .onChange(of: welcomeIntroStep) { _, _ in KuroVoiceSynthesizer.shared.speak(KuroGibberishGenerator.gibberish(for: currentScriptKey)) }
        .onChange(of: energyPurchaseSuccess) { _, _ in KuroVoiceSynthesizer.shared.speak(KuroGibberishGenerator.gibberish(for: currentScriptKey)) }
    }

    /// 监护人协议 / 进化考核结尾顺带告知巢穴入口
    private var scriptSubtitle: String? {
        switch mode {
        case .guardian where guardianResult != nil: return KuroScripts.nestHint
        case .evolution: return KuroScripts.nestHint
        case .welcomeIntro: return nil
        default: return nil
        }
    }

    private var currentScriptLine: String {
        switch mode {
        case .admin:
            return KuroScripts.adminGreeting
        case .guardian:
            if let result = guardianResult {
                return result ? KuroScripts.guardianSuccess : KuroScripts.guardianPartialOrDeclined
            }
            switch guardianStep {
            case 0: return KuroScripts.guardianLine1
            case 1: return KuroScripts.guardianMobiReply
            case 2: return KuroScripts.guardianLine2
            default: return KuroScripts.guardianLine2
            }
        case .welcomeIntro:
            switch welcomeIntroStep {
            case 0: return KuroScripts.welcomeIntroScreen1
            case 1: return KuroScripts.welcomeIntroScreen2
            default: return KuroScripts.welcomeIntroPermissionPrompt
            }
        case .evolution:
            return KuroScripts.evolutionScan
        case .energy:
            return energyPurchaseSuccess ? KuroScripts.energyBillSuccess : KuroScripts.energyBillWarning
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch mode {
        case .admin:
            HStack(spacing: 16) {
                Button(KuroScripts.adminButtonSettings) {
                    if case .admin(let onSettings, _) = mode { onSettings() }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Button(KuroScripts.adminButtonReset, role: .destructive) {
                    showResetConfirm = true
                }
                .buttonStyle(.bordered)
            }

        case .guardian:
            if let result = guardianResult {
                Button("关闭") {
                    if case .guardian(_, let onClose) = mode { onClose(result) }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else if guardianStep < 2 {
                Button("下一步") {
                    guardianStep += 1
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack(spacing: 16) {
                    Button(KuroScripts.guardianButtonDecline) {
                        if case .guardian(_, let onClose) = mode { onClose(false) }
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    Button(KuroScripts.guardianButtonAgree) {
                        if case .guardian(let onRequest, _) = mode {
                            onRequest { granted in
                                DispatchQueue.main.async { guardianResult = granted }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

        case .welcomeIntro:
            if welcomeIntroStep < 2 {
                Button("下一步") {
                    welcomeIntroStep += 1
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack(spacing: 16) {
                    Button(KuroScripts.welcomeIntroButtonLater) {
                        if case .welcomeIntro(_, let onClose) = mode { onClose(false) }
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    Button(KuroScripts.welcomeIntroButtonAgree) {
                        if case .welcomeIntro(let onRequest, let onClose) = mode {
                            onRequest { granted in
                                DispatchQueue.main.async {
                                    onClose(granted)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

        case .evolution:
            Button(KuroScripts.evolutionButtonPermit) {
                if case .evolution(let onPermit) = mode { onPermit() }
                dismiss()
            }
            .buttonStyle(.borderedProminent)

        case .energy:
            if energyPurchaseSuccess {
                Button("关闭") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack(spacing: 16) {
                    Button("稍后") {
                        if case .energy(_, let onDismiss) = mode { onDismiss() }
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    Button(KuroScripts.energyBillButton) {
                        if case .energy(let onPurchase, _) = mode {
                            onPurchase { success in
                                DispatchQueue.main.async { energyPurchaseSuccess = success }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func performReset() {
        if case .admin(_, let onReset) = mode { onReset() }
        dismiss()
    }
}

#if DEBUG
struct KuroOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        KuroOverlayView(mode: .admin(onSettings: {}, onReset: {}))
    }
}
#endif
