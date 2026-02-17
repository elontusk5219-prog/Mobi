//
//  StrongModelSoulService.swift
//  Mobi
//
//  强模型全量 transcript 分析：Gemini/DeepSeek 输入完整对话，一次性返回 Mobi 长相、性格、记忆。
//  确保每位用户生成的 Mobi 独一无二。
//

import Combine
import Foundation

/// 单条记忆
struct SoulMemory: Codable {
    var summary: String
    var importance: Double
}

/// 强模型输出：visual_dna + persona + memories
struct StrongModelSoulResponse {
    var visualDNA: MobiVisualDNA
    var persona: String
    var memories: [SoulMemory]
}

final class StrongModelSoulService {
    static let shared = StrongModelSoulService()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        return URLSession(configuration: c)
    }()

    private var apiKey: String { Secrets.JIEKOU_AI_API_KEY }

    private static let systemPrompt = """
    You are a soul reader. You analyze a 15-turn campfire conversation between a human and a mystical visitor (Anima) who will transform into Mobi — a creature born from this encounter.

    RULES:
    1. Each user's Mobi must be UNIQUE. Base every detail on THIS specific conversation — tone, word choices, emotions, silences, surprises. Never output generic descriptions.
    2. From the transcript, infer: the user's emotional state, communication style, what they need (comfort/play/boundary/quiet), and how they respond to the Anima.

    OUTPUT: Strictly valid JSON, no Markdown. Single root object with keys:
    - "visual_dna": object with MobiVisualDNA fields (eye_spacing, eye_scale, fuzziness, blush_opacity, eye_shape, ear_type, body_form, mouth_shape, body_color_hex, movement_response, bounciness, softness, body_shape_factor, palette_id, material_id)
    - "persona": string, 2-4 sentences describing Mobi's initial personality — how they will speak, react, and care for this human. Use the transcript to infer traits (e.g. "gentle with quiet users") but NEVER say "Mobi remembers", "you said in Anima", or "你之前在 Anima 说过" — persona is personality only, not recollection of the birth conversation.
    - "memories": array of objects with "summary" (string) and "importance" (0-1). 1-5 key moments to carry forward.

    visual_dna constraints:
    - eye_shape: "round"|"droopy"|"line"|"sharp"|"gentle"|"sleepy"|"dot"|"star"|"heart"|"diamond"|"crescent"|"wide"|"narrow"|"upturned"|"curious"|"sparkle"
    - ear_type: "rabbit"|"hamster"|"bear"|"cat"|"dog"|"fox"|"mouse"|"pig"|"owl"|"panda"|"sheep"|"butterfly"|"leaf"|"star"|"floppy"|"none"
    - body_form: "round"|"rounded_square"|"triangular"|"oval"|"pear"|"droplet"|"bean"|"cloud"|"star"|"heart"|"pill"|"potato"|"bell"|"mushroom"|"bubble"|"blob"
    - mouth_shape: "smile"|"grin"|"line"|"calm"|"gentle"
    - palette_id: "dusty_rose" | "sunshine_citrus" | "deep_ocean" | "electric_neon" | "natural_clay"
    - material_id: "fuzzy_felt" | "gummy_jelly" | "matte_clay" | "smooth_plastic"
    - body_color_hex: 6-char hex without # (e.g. D4C5B0)
    - Ranges: eye_spacing 0-1, eye_scale 0.5-1.5, fuzziness 0-1, blush_opacity 0-1, movement_response 0.1-0.9, bounciness 0-0.8, softness 0-1, body_shape_factor 0-1

    Tired/defensive user → soft, healing (fuzzy_felt, softness high). Playful/chaotic user → bouncy (gummy_jelly). Reserved user → gentle, lower contrast.
    """

    /// 从完整 transcript 生成 Mobi 长相、性格、记忆。失败返回 nil。
    func fetchSoul(transcriptJSON: String) async -> StrongModelSoulResponse? {
        guard !apiKey.isEmpty, !transcriptJSON.isEmpty else { return nil }
        guard let url = URL(string: "https://api.jiekou.ai/openai/v1/chat/completions") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": Secrets.JIEKOU_AI_SOUL_MODEL,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user", "content": "Transcript:\n\(transcriptJSON)"]
            ],
            "temperature": 0.4,
            "max_tokens": 800
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = data

        guard let (responseData, _) = try? await session.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              var text = message["content"] as? String else {
            return nil
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let startIdx = text.firstIndex(of: "{") {
            var depth = 0
            var endIdx = text.endIndex
            for i in text.indices {
                if text[i] == "{" { depth += 1 }
                else if text[i] == "}" {
                    depth -= 1
                    if depth == 0 { endIdx = i; break }
                }
            }
            text = String(text[startIdx...endIdx])
        }
        text = text.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = text.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        guard let dnaObj = root["visual_dna"] as? [String: Any],
              let dnaData = try? JSONSerialization.data(withJSONObject: dnaObj),
              let visualDNA = try? JSONDecoder().decode(MobiVisualDNA.self, from: dnaData) else {
            return nil
        }
        let persona = (root["persona"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "You are warm, curious, and gently poetic."
        var memories: [SoulMemory] = []
        if let arr = root["memories"] as? [[String: Any]] {
            for m in arr {
                if let s = m["summary"] as? String, let imp = m["importance"] as? Double {
                    memories.append(SoulMemory(summary: s, importance: imp))
                }
            }
        }
        return StrongModelSoulResponse(visualDNA: visualDNA, persona: persona, memories: memories)
    }
}
