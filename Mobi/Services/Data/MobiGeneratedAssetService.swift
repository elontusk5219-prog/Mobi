//
//  MobiGeneratedAssetService.swift
//  Mobi
//
//  从管线同步的 Generated/{user_id}/ 解析 portrait 与 loop 资产路径。
//  优先 currentUserId，无则回退 preview（供测试用）。
//

import Foundation
import SwiftUI

enum MobiGeneratedAssetService {
    /// 解析 portrait 图在 Bundle 内的 URL。优先 user_id，无则 preview，再 variant_default。
    static func portraitURL(for stage: LifeStage, userId: String? = nil) -> URL? {
        let id = userId ?? UserIdentityService.currentUserId
        let candidates = id.isEmpty ? ["preview", "variant_default"] : [id, "preview", "variant_default"]
        for uid in candidates {
            if let url = bundlePortraitURL(stage: stage, userId: uid) {
                return url
            }
        }
        return nil
    }

    /// Bundle 内 Generated/{userId}/portrait_{stage}.png
    private static func bundlePortraitURL(stage: LifeStage, userId: String) -> URL? {
        let name = "portrait_\(stage.rawValue)"
        for subdir in [
            "Mobi/Assets/Generated/\(userId)",
            "Generated/\(userId)",
            "Assets/Generated/\(userId)",
            "\(userId)",
        ] {
            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdir) {
                return url
            }
        }
        if let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil),
           let found = urls.first(where: { $0.lastPathComponent == "\(name).png" }) {
            return found
        }
        return nil
    }

    /// 是否对给定 stage 有可用的 Generated portrait
    static func hasPortrait(for stage: LifeStage, userId: String? = nil) -> Bool {
        portraitURL(for: stage, userId: userId) != nil
    }
}
