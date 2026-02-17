//
//  GenesisCommitAPI.swift
//  Mobi
//
//  Contract for 10s transition: 优先强模型 transcript 分析；无 transcript 时回退 SoulProfile。
//

import Foundation

/// Response from backend after commit (target: within 7s).
struct GenesisCommitResponse {
    var colorHex: String
    var shape: String?
    var voiceId: String?
    var systemPromptSnippet: String?
    /// Full visual DNA from LLM (palette, material, physics).
    var visualDNA: MobiVisualDNA?
    /// 自然语言人设描述，供 Room Doubao 使用。
    var persona: String?
    /// 初始记忆，供 MemoryDiaryService 使用。
    var memories: [SoulMemory]?
}

/// Result of commit (upload profile or transcript, wait for config).
enum GenesisCommitResult {
    case success(GenesisCommitResponse)
    case failure
    case timeout
}

/// Genesis commit: 优先 transcript → StrongModelSoulService；否则 profile → GeminiVisualDNAService。
enum GenesisCommitAPI {
    /// 优先用 transcript 调用强模型；transcript 为空时回退 SoulProfile。
    static func commit(transcriptJSON: String?, profile: SoulProfile) async -> GenesisCommitResult {
        if let transcript = transcriptJSON, !transcript.isEmpty, transcript != "[]" {
            if let soul = await StrongModelSoulService.shared.fetchSoul(transcriptJSON: transcript) {
                let hex = soul.visualDNA.bodyColorHex.hasPrefix("#") ? String(soul.visualDNA.bodyColorHex.dropFirst()) : soul.visualDNA.bodyColorHex
                return .success(GenesisCommitResponse(
                    colorHex: hex,
                    shape: nil,
                    voiceId: nil,
                    systemPromptSnippet: soul.persona,
                    visualDNA: soul.visualDNA,
                    persona: soul.persona,
                    memories: soul.memories
                ))
            }
        }
        let json = profile.toJSONSummary()
        guard let dna = await GeminiVisualDNAService.shared.fetchVisualDNA(profileJSON: json) else {
            return .failure
        }
        let hex = dna.bodyColorHex.hasPrefix("#") ? String(dna.bodyColorHex.dropFirst()) : dna.bodyColorHex
        return .success(GenesisCommitResponse(
            colorHex: hex,
            shape: nil,
            voiceId: nil,
            systemPromptSnippet: nil,
            visualDNA: dna,
            persona: nil,
            memories: nil
        ))
    }
}
