//
//  GeminiVisualDNAService.swift
//  Mobi
//
//  LLM (via 接口AI) generates MobiVisualDNA from SoulProfile. Used during Genesis transition.
//

import Foundation

final class GeminiVisualDNAService {
    static let shared = GeminiVisualDNAService()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 45
        return URLSession(configuration: c)
    }()

    private var apiKey: String { Secrets.JIEKOU_AI_API_KEY }

    private static let systemPrompt = """
    You are a physics-based character engine. Analyze the user's soul to determine their Mobi entity's visual and physical properties.
    SoulProfile may include: warmth, energy, chaos, draftEnergy, draftIntimacy, draftColorId, draftMood, draftOpenness, draftCommunicationStyle, draftShellType, draftPersonalityBase, shadowSummary (multi-turn analyst notes).
    Complementary logic: high-pressure/tired user → healing, slow movement, soft; playful/chaotic user → playful, bouncy; defensive/armored user → matte, grounded. Resonant logic: warm user → warm palette; reserved user → gentle, lower contrast.
    material_id by shell_type: Armored → matte_clay; Soft → fuzzy_felt; Resilient → gummy_jelly or smooth_plastic. personality_base hints: Healing → fuzzy_felt, softness high; Playful → gummy_jelly, bounciness up; Quiet → matte_clay, movement_response low.
    Output strictly valid JSON (no Markdown, no code blocks). Keys: eye_spacing, eye_scale, fuzziness, blush_opacity, eye_shape, ear_type, body_form, mouth_shape, body_color_hex, movement_response, bounciness, softness, body_shape_factor, palette_id, material_id.
    Ranges: eye_spacing 0-1, eye_scale 0.5-1.5, fuzziness 0-1, blush_opacity 0-1, movement_response 0.1-0.9, bounciness 0-0.8, softness 0-1, body_shape_factor 0-1.
    eye_shape: "round"|"droopy"|"line"|"sharp"|"gentle"|"sleepy"|"dot"|"star"|"heart"|"diamond"|"crescent"|"wide"|"narrow"|"upturned"|"curious"|"sparkle".
    ear_type: "rabbit"|"hamster"|"bear"|"cat"|"dog"|"fox"|"mouse"|"pig"|"owl"|"panda"|"sheep"|"butterfly"|"leaf"|"star"|"floppy"|"none".
    body_form: "round"|"rounded_square"|"triangular"|"oval"|"pear"|"droplet"|"bean"|"cloud"|"star"|"heart"|"pill"|"potato"|"bell"|"mushroom"|"bubble"|"blob".
    mouth_shape: "smile"|"grin"|"line"|"calm"|"gentle".
    body_color_hex: 6-char hex without # (e.g. D4C5B0).
    palette_id: "dusty_rose" | "sunshine_citrus" | "deep_ocean" | "electric_neon" | "natural_clay".
    material_id: "fuzzy_felt" | "gummy_jelly" | "matte_clay" | "smooth_plastic".
    """

    /// Generate MobiVisualDNA from SoulProfile JSON. Returns nil on failure.
    func fetchVisualDNA(profileJSON: String) async -> MobiVisualDNA? {
        guard !apiKey.isEmpty, !profileJSON.isEmpty else { return nil }
        guard let url = URL(string: "https://api.jiekou.ai/openai/v1/chat/completions") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": Secrets.JIEKOU_AI_SOUL_MODEL,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user", "content": "Soul profile: \(profileJSON)"]
            ],
            "temperature": 0.3,
            "max_tokens": 400
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
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            text = String(text[start.lowerBound...end.upperBound])
        }
        text = text.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = text.data(using: .utf8),
              let dna = try? JSONDecoder().decode(MobiVisualDNA.self, from: jsonData) else {
            return nil
        }
        return dna
    }
}
