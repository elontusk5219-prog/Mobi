//
//  JiekouAIEntropyService.swift
//  Mobi
//
//  接口AI 平台 DeepSeek R1：计算对话 entropy（话题/多样性）0...1，用于 ΔSurprise。
//  文档：https://docs.jiekou.ai/docs/models/reference-llm-create-chat-completion
//

import Foundation

final class JiekouAIEntropyService {
    static let shared = JiekouAIEntropyService()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    private var apiKey: String { Secrets.JIEKOU_AI_API_KEY }

    /// 请求 entropy：0 = 重复/同主题，1 = 非常跳跃多样。使用最近 N 条用户话。
    func fetchEntropy(utterances: [String]) async -> Double {
        guard !apiKey.isEmpty, !utterances.isEmpty else { return 0 }
        let list = utterances.suffix(7).map { $0.prefix(150) }.joined(separator: "\n")
        let prompt = """
        你是一个指标。根据下面用户的多条发言（每行一条），仅输出一个 0.0 到 1.0 之间的浮点数，表示话题/情绪多样性。0=非常重复、同一主题，1=非常跳跃、多样。不要解释，不要其他文字。
        发言：
        \(list)
        """
        guard let url = URL(string: "https://api.jiekou.ai/openai/v1/chat/completions") else { return 0 }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": Secrets.JIEKOU_AI_DEEPSEEK_MODEL,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.1,
            "max_tokens": 16
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return 0 }
        request.httpBody = data
        guard let (responseData, _) = try? await session.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else { return 0 }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Double(trimmed.filter { $0.isNumber || $0 == "." }) {
            return min(1, max(0, value))
        }
        if let value = Double(trimmed) { return min(1, max(0, value)) }
        return 0
    }
}
