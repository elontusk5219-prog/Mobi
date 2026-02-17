//
//  EvolutionProfileService.swift
//  Mobi
//
//  画像进化 API 客户端：GET 进化/人格槽结果。未配置 baseURL 或请求失败时返回契约 Mock。
//  约定见 docs/画像-进化接口契约.md。
//

import Foundation

@MainActor
final class EvolutionProfileService {
    static let shared = EvolutionProfileService()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    private init() {}

    /// 获取当前用户的进化与人格槽数据。未配置 baseURL 或请求失败时返回 Mock，不返回 nil。
    /// 请求会携带当前账号 userId，确保画像按账号隔离（query + X-User-Id）。
    func fetch() async -> EvolutionProfileResponse {
        let userId = UserIdentityService.currentUserId
        let baseURL = Secrets.profileEvolutionBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !baseURL.isEmpty else { return Self.mockResponse() }
        var urlString = "\(baseURL)/profile/evolution"
        if !userId.isEmpty {
            urlString += "?userId=\(userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId)"
        }
        guard let url = URL(string: urlString) else { return Self.mockResponse() }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if !userId.isEmpty {
                request.setValue(userId, forHTTPHeaderField: "X-User-Id")
            }
            if !Secrets.everMemOSAPIKey.isEmpty {
                request.setValue(Secrets.everMemOSAPIKey, forHTTPHeaderField: "Authorization")
            }
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return Self.mockResponse()
            }
            let decoded = try JSONDecoder().decode(EvolutionProfileResponse.self, from: data)
            return decoded
        } catch {
            return Self.mockResponse()
        }
    }

    /// 契约 §5.1 Mock 响应（未配置或失败时使用）。返回 newborn 以便未接画像时能走幼年乱码语等流程。
    static func mockResponse() -> EvolutionProfileResponse {
        EvolutionProfileResponse(
            lifeStage: "newborn",
            slotProgress: 0.2,
            completeness: 0.25,
            dimensionConfidences: [
                "openness": 0.6,
                "conscientiousness": 0.4,
                "extraversion": 0.5,
                "agreeableness": 0.7,
                "emotionalStability": 0.45
            ],
            confidenceDecay: false,
            unlockedFeatures: [],
            languageHabits: nil
        )
    }
}
