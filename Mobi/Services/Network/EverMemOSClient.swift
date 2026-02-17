//
//  EverMemOSClient.swift
//  Mobi
//
//  EverMemOS REST API 封装：POST memories、GET search。
//  用于 Room 阶段跨会话记忆的存储与检索。
//

import Foundation

/// EverMemOS 单条消息存储请求
struct EverMemOSStoreRequest: Encodable {
    let message_id: String
    let create_time: String
    let sender: String
    let content: String
    let role: String?
    let sender_name: String?
    let user_id: String?
    let group_id: String?
    let group_name: String?
    let refer_list: [String]?
}

/// EverMemOS 检索请求
struct EverMemOSSearchRequest: Encodable {
    let query: String?
    let user_id: String?
    let group_id: String?
    let retrieve_method: String?
    let memory_types: [String]?
    let top_k: Int?
    let start_time: String?
    let end_time: String?
}

/// EverMemOS 检索结果中的单条记忆
struct EverMemOSMemoryItem: Decodable {
    let memory_type: String?
    let user_id: String?
    let timestamp: String?
    let content: String?
    let summary: String?
    let group_id: String?
}

/// EverMemOS API 响应通用结构
struct EverMemOSResponse<T: Decodable>: Decodable {
    let status: String?
    let message: String?
    let result: T?
}

/// 检索结果中按 memory_type 分组的记忆组
struct EverMemOSMemoriesGroup: Decodable {
    let episodic_memory: [EverMemOSMemoryItem]?
}

/// 检索结果
struct EverMemOSSearchResult: Decodable {
    let memories: [EverMemOSMemoriesGroup]?
    let total_count: Int?
    let has_more: Bool?
}

/// EverMemOS HTTP 客户端
final class EverMemOSClient {
    static let shared = EverMemOSClient()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        return URLSession(configuration: c)
    }()

    private var baseURL: String { Secrets.everMemOSBaseURL }
    private var apiKey: String { Secrets.everMemOSAPIKey }

    private init() {}

    /// 按 group_id 或 user_id 删除记忆；至少传一个。memory_id 默认 __all__ 表示该维度下全删。
    /// 注意：API 不允许 memory_id、user_id、group_id 全部为 __all__，需至少一个具体 ID。批量清空请用 Config/clear-evermemos-all-users.sh 按 group_id 列表逐个删除。
    func deleteMemories(userId: String? = nil, groupId: String? = nil) async -> Bool {
        guard !apiKey.isEmpty, !baseURL.isEmpty else {
            print("[EverMemOS] API Key or Base URL not configured, skip delete")
            return false
        }
        guard userId != nil || groupId != nil else {
            print("[EverMemOS] deleteMemories requires at least userId or groupId")
            return false
        }
        guard let url = URL(string: "\(baseURL)/api/v0/memories") else { return false }

        var body: [String: String] = [:]
        body["memory_id"] = "__all__"
        body["user_id"] = userId ?? "__all__"
        body["group_id"] = groupId ?? "__all__"

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("[EverMemOS] Delete failed: \(response)")
                return false
            }
            return true
        } catch {
            print("[EverMemOS] Delete error: \(error)")
            return false
        }
    }

    /// 存储单条消息
    func storeMemory(_ request: EverMemOSStoreRequest) async -> Bool {
        guard !apiKey.isEmpty, !baseURL.isEmpty else {
            print("[EverMemOS] API Key or Base URL not configured, skip store")
            return false
        }
        guard let url = URL(string: "\(baseURL)/api/v0/memories") else { return false }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            let (_, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("[EverMemOS] Store failed: \(response)")
                return false
            }
            return true
        } catch {
            print("[EverMemOS] Store error: \(error)")
            return false
        }
    }

    /// 检索记忆
    func searchMemories(
        query: String,
        userId: String,
        groupId: String? = nil,
        retrieveMethod: String = "hybrid",
        topK: Int = 8,
        startTime: String? = nil,
        endTime: String? = nil
    ) async -> [EverMemOSMemoryItem] {
        guard !apiKey.isEmpty, !baseURL.isEmpty else {
            print("[EverMemOS] API Key or Base URL not configured, skip search")
            return []
        }
        guard let url = URL(string: "\(baseURL)/api/v0/memories/search") else { return [] }

        let body = EverMemOSSearchRequest(
            query: query,
            user_id: userId,
            group_id: groupId,
            retrieve_method: retrieveMethod,
            memory_types: ["episodic_memory"],
            top_k: topK,
            start_time: startTime,
            end_time: endTime
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("[EverMemOS] Encode search body error: \(error)")
            return []
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("[EverMemOS] Search failed: \(response)")
                return []
            }
            let decoded = try JSONDecoder().decode(EverMemOSResponse<EverMemOSSearchResult>.self, from: data)
            guard let result = decoded.result, let memories = result.memories else { return [] }
            var items: [EverMemOSMemoryItem] = []
            for group in memories {
                if let arr = group.episodic_memory {
                    items.append(contentsOf: arr)
                }
            }
            return items
        } catch {
            print("[EverMemOS] Search error: \(error)")
            return []
        }
    }
}
