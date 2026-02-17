//
//  Secrets.swift
//  Mobi
//
//  Doubao / 火山引擎 API 凭据。生产环境建议用 xcconfig 或环境变量覆盖，勿提交真实值。
//

import Combine
import Foundation

enum Secrets {
    static let DOUBAO_APP_ID = ProcessInfo.processInfo.environment["DOUBAO_APP_ID"] ?? "8712004137"
    static let DOUBAO_TOKEN = ProcessInfo.processInfo.environment["DOUBAO_TOKEN"] ?? "D_p5xzbNPKXDgaSOSUScoZhI59mw_vhK"
    static let DOUBAO_SECRET_KEY = ProcessInfo.processInfo.environment["DOUBAO_SECRET_KEY"] ?? "8bQzkMU-EU7r_ZGoSgjwSrSesJ2yOltK"

    /// Aliases for Volcengine WebSocket auth (pulled from env or defaults).
    static var doubaoAppID: String { DOUBAO_APP_ID }
    static var doubaoToken: String { DOUBAO_TOKEN }

    /// 接口AI API Key（DeepSeek R1 等，用于 entropy）。优先环境变量 JIEKOU_AI_API_KEY。
    static let JIEKOU_AI_API_KEY = ProcessInfo.processInfo.environment["JIEKOU_AI_API_KEY"] ?? "sk_KBncy-8praWJGPZOKgxCrRDIDuBzxCpltKB8v9AbLnY"

    /// 接口AI 支持的 DeepSeek R1 模型 ID。定价页：deepseek/deepseek-r1-0528（推理慢，适合 entropy 等轻量任务）
    static let JIEKOU_AI_DEEPSEEK_MODEL = "deepseek/deepseek-r1-0528"

    /// 接口AI 强模型 Soul 分析用：Gemini 2.5 Flash，响应快（5–15s），适合 transcript→DNA 结构化输出
    static let JIEKOU_AI_SOUL_MODEL = "gemini-2.5-flash"

    // MARK: - EverMemOS (console.evermind.ai)
    /// EverMemOS API Key，黑客松发放；未配置时记忆功能静默降级
    static let everMemOSAPIKey = ProcessInfo.processInfo.environment["EVERMEMOS_API_KEY"] ?? ""
    /// EverMemOS Base URL，默认云端；本地自部署可改为 http://localhost:1995
    static let everMemOSBaseURL = ProcessInfo.processInfo.environment["EVERMEMOS_BASE_URL"] ?? "https://api.evermind.ai"

    // MARK: - 用户画像 / 进化 API
    /// 画像进化 API 根地址；未配置或空时客户端使用 Mock，见 docs/画像-进化接口契约.md §5。
    static let profileEvolutionBaseURL = ProcessInfo.processInfo.environment["PROFILE_EVOLUTION_BASE_URL"] ?? ""

}
