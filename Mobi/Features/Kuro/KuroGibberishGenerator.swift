//
//  KuroGibberishGenerator.swift
//  Mobi
//
//  库洛语：机械、冷淡风格音节表，按 script key 确定性生成 gibberish 句；并解析出音节序列供合成播放。
//

import Foundation

enum KuroGibberishGenerator {
    /// 库洛语音节（短、硬、偏数字/协议感）
    private static let syllables = ["Krr", "Zt", "Vz", "Tk", "Nn", "Kt", "Px", "Qv", "Pk", "Pr"]
    private static let pauseMarks = ["—", "…"]

    /// 根据 script key 生成确定性库洛语字符串（同一 key 永远得到同一句）
    static func gibberish(for scriptKey: String) -> String {
        var seed = UInt64(bitPattern: Int64(scriptKey.hashValue))
        if seed == 0 { seed = 1 }
        let wordCount = 3 + (Int(seed % 5))  // 3–7 个「词」
        var parts: [String] = []
        for i in 0..<wordCount {
            let n = Int((seed >> (i * 4)) % UInt64(syllables.count))
            let syl = syllables[n]
            if i > 0 && (seed >> (i * 3 + 1)) % 3 == 0 {
                parts.append("—")
            }
            if i > 0 && (seed >> (i * 2)) % 2 == 0, parts.last != "—" {
                parts[parts.count - 1] += " " + syl
            } else {
                parts.append(syl)
            }
        }
        return parts.joined(separator: ". ") + "."
    }

    /// 从库洛语字符串解析出音节与停顿序列，供 KuroVoiceSynthesizer 按序播放
    static func syllables(for gibberishString: String) -> [String] {
        let sylLower = Set(syllables.map { $0.lowercased() })
        let pauseSet = Set(pauseMarks)
        let tokens = gibberishString
            .components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
            .filter { !$0.isEmpty }
        var result: [String] = []
        for token in tokens {
            if pauseSet.contains(token) {
                result.append(token)
            } else if sylLower.contains(token.lowercased()) {
                let cap = token.prefix(1).uppercased() + token.dropFirst().lowercased()
                result.append(cap)
            }
        }
        if result.isEmpty {
            result = ["Krr", "Zt", "Vz"]
        }
        return result
    }
}
