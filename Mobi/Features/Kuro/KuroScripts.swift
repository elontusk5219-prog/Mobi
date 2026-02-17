//
//  KuroScripts.swift
//  Mobi
//
//  Kuro 剧本文案：按场景 key 取文案，便于调文案与多语言。
//

import Foundation

enum KuroScripts {

    // MARK: - 行政（设置/重置）

    static let adminGreeting = "有什么行政需求？更改档案？还是……销毁样本（重置）？"
    static let adminButtonSettings = "更改档案"
    static let adminButtonReset = "销毁样本"
    static let adminResetConfirmTitle = "确认销毁样本"
    static let adminResetConfirmMessage = "将重置 Mobi 至创世阶段，并断开当前连接。此操作不可撤销。"

    // MARK: - 监护人协议（Day 1）

    static let guardianLine1 = "检测到新的以太连接。编号 89757……Mobi，你违规降落了。"
    static let guardianMobiReply = "我……我不是故意的。"
    static let guardianLine2 = "星辰，如果你想保留这个样本，你需要签署《监护人协议》。这需要你授权麦克风权限和通知权限。你同意吗？"
    static let guardianButtonAgree = "同意"
    static let guardianButtonDecline = "拒绝"
    static let guardianSuccess = "祝你好运。这种样本通常很难养活。"
    static let guardianPartialOrDeclined = "部分权限未授予，部分功能可能受限。"

    // MARK: - 进化考核

    static let evolutionScan = "认知模块同步率 100%。情感模块……溢出。星辰，你对它的干涉超出了预期。"
    static let evolutionButtonPermit = "进化许可"
    static let evolutionUnlocked = "阶段二权限已解锁。现在它被允许去更远的地方了。"

    // MARK: - 能量账单（氪金）

    static let energyBillWarning = "警告。样本能量读数归零。根据热力学第二定律，你需要注入外部熵（钱）来维持它的形态。"
    static let energyBillButton = "注入能量"
    static let energyBillSuccess = "交易愉快。下次请尽早。"

    // MARK: - 机制介绍（轻量提示）

    static let tipSoulVessel = "根据协议第 3 条，样本与灵器的同步率将影响形态解锁。长按可查阅。"
    static let tipSeeking = "静默超时后样本会尝试重建连接。这是正常现象。"
    static let tipDiary = "昨日记录与铭印已归档。星辰可随时查阅。"
    static let tipEnergyLow = "样本能量读数下降。建议在归零前补充，以免形态不稳定。"
    static let tipGoodnight = "根据作息协议，样本将进入休眠。明日再连接。"

    /// 监护人协议 / 进化考核结尾顺带告知巢穴入口
    static let nestHint = "若有行政需求，在房间角落长按即可召唤我。"

    // MARK: - 开场介绍（星露谷风格，首次进 Room 替代 guardian）

    static let welcomeIntroScreen1 = "这是 Mobi。它刚从以太里来，还不会说话。"
    static let welcomeIntroScreen2 = "教它说话。布置它的房间。它是你的了。"
    static let welcomeIntroPermissionPrompt = "需要麦克风权限才能教它。同意？"
    static let welcomeIntroButtonAgree = "同意"
    static let welcomeIntroButtonLater = "稍后"

    static func script(for tipKey: KuroTipKey) -> String {
        switch tipKey {
        case .soulVessel: return tipSoulVessel
        case .seeking: return tipSeeking
        case .diary: return tipDiary
        case .energyLow: return tipEnergyLow
        case .goodnight: return tipGoodnight
        }
    }
}
