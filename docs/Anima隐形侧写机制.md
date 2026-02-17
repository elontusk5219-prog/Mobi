# Anima 隐形侧写机制

**文档用途：** 技术说明。Anima 对话中不收集 Social Stats（职业、年龄、居住地），而是通过 **Soul Stats** 与 **Shadow Analysis** 映射到 Mobi 性格参数。

---

## 1. 设计目标

| 不收集 | 改为 |
|--------|------|
| Social Stats（职业、年龄、居住地） | Soul Stats（攻击性/温和性、混沌/秩序、外向/内向、感性/理性） |
| 直问直答 | 隐形引导：Illusions of Choice（二元选项），用户选择 → 潜意识暴露 |
| 显式问卷 | Shadow Analysis：LLM 每轮输出「分析师线程」JSON，用户不可见 |

---

## 2. 数据流

```
MobiPrompts (Illusions of Choice + METADATA_UPDATE 格式)
    → SoulMetadataParser.parseAndStripAll → MetadataDraftUpdate
    → UserPsycheModel.updateDraftFromMetadata → UserProfileDraft / shadowThoughtProcesses
    → buildSoulProfile() → SoulProfile.toJSONSummary()
    → GenesisCommitAPI / GeminiVisualDNAService → MobiVisualDNA (material_id, 物理参数)
```

---

## 3. 核心字段

### 3.1 METADATA_UPDATE（LLM 输出）

| 字段 | 说明 |
|------|------|
| `thought_process` | 简短分析（如 "User said X, indicates Y"） |
| `current_mood` | Aggressive / Playful / Tired / Defensive 等 |
| `energy_level` | High / Low |
| `openness` | High / Low |
| `communication_style` | Direct / Evasive / Warm / Blunt 等 |
| `shell_type` | Armored / Soft / Resilient（Mobi 外壳类型） |
| `personality_base` | 互补或共鸣人格基调（Healing / Playful / Quiet / Resilient / Warm） |
| `energy_tag`, `intimacy_tag`, `color_id`, `vibe_keywords` | 原有字段，保留 |

### 3.2 SoulProfile 扩展（供 Gemini）

| 字段 | 来源 |
|------|------|
| `draftMood` | 最新 current_mood |
| `draftOpenness` | 最新 openness |
| `draftCommunicationStyle` | 最新 communication_style |
| `draftShellType` | 最新 shell_type |
| `draftPersonalityBase` | 最新 personality_base |
| `shadowSummary` | 多轮 thought_process 摘要（最近 10 轮拼接） |

---

## 4. Mobi 映射逻辑（GeminiVisualDNAService）

| 用户侧写 | Mobi 表现 |
|----------|-----------|
| shell_type: Armored | material_id: matte_clay |
| shell_type: Soft | material_id: fuzzy_felt |
| shell_type: Resilient | gummy_jelly / smooth_plastic |
| personality_base: Healing | fuzzy_felt, softness 高 |
| personality_base: Playful | gummy_jelly, bounciness 高 |
| personality_base: Quiet | matte_clay, movement_response 低 |
| 高压 / 疲惫用户 | 治愈系、慢节奏、软 |
| 搞怪 / 混沌用户 | 吐槽役、活泼、有弹性 |

---

## 5. 实施位置

| 组件 | 文件 |
|------|------|
| Prompt（Illusions of Choice、METADATA 格式） | `MobiPrompts.swift` |
| 解析 METADATA_UPDATE | `SoulMetadataParser.swift` |
| 累积侧写 | `UserPsycheModel.swift`（UserProfileDraft、shadowThoughtProcesses） |
| 阶段指令（Illusions of Choice、Shadow Analysis） | `SoulHookController.swift` |
| 后端 DNA 生成 | `GeminiVisualDNAService.swift` |

---

*最后更新：2025-02*
