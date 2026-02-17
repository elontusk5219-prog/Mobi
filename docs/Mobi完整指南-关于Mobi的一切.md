# Mobi 完整指南：关于 Mobi 的一切

**文档用途：** 综合本对话及项目文档，整理 Mobi 的完整设计、机制与实现。作为 Mobi 相关问题的权威参考。

**维护：** 2025-02 整理，随实现更新。

---

## 目录

1. [产品定位与叙事](#1-产品定位与叙事)
1.5 [Kuro：系统监督者](#15-kuro系统监督者)
2. [生命周期与阶段](#2-生命周期与阶段)
3. [Mobi 的诞生：Anima 遗忘设定](#3-mobi-的诞生anima-遗忘设定)
4. [Mobi 阶段 1/2/3 与智能层级](#4-mobi-阶段-123-与智能层级)
5. [视觉资产与外形](#5-视觉资产与外形)
6. [大脑与 DNA 机制](#6-大脑与-dna-机制)
7. [交互驱动](#7-交互驱动)
8. [运动与物理](#8-运动与物理)
9. [学习与记忆](#9-学习与记忆)
10. [Mobi 阶段大脑设计](#10-mobi-阶段大脑设计)
11. [自我意识与身份](#11-自我意识与身份)
12. [文件索引](#12-文件索引)
13. [待办与缺口](#13-待办与缺口)

---

## 1. 产品定位与叙事

| 维度 | 说明 |
|------|------|
| **核心理念** | "Not an App, but a Living Soul." |
| **Mobi 是什么** | 从以太（Ether）中经由用户 15 轮对话「塑造」出来的生灵，在 First Room 中与用户相伴 |
| **Anima** | 诞生前的「过客意识」，营火旁偶遇的陌生人，不知自己将诞生 |
| **Amnesia** | Anima 在 Turn 13+ 察觉被拉入时预言："I will forget this conversation. But my soul will remember your frequency." |

### 1.5 Kuro：系统监督者

Kuro（库洛）是规则与系统的拟人化，与 Mobi 形成叙事对照：**Mobi = 感性、混沌、纯真（潜意识/本心）；Kuro = 理性、秩序、功利（系统管理员）**。Mobi 怕它但必须服从；用户对商业化或规则的不满可指向 Kuro，而对 Mobi 保持怜爱。

| 维度 | 说明 |
|------|------|
| **无 UI 的 UI** | 所有「硬功能」由 Kuro 出面承接：设置/重置（长按巢穴）、Day 1 监护人协议（麦克风/通知权限）、进化考核（人格槽满溢）、能量账单（精力耗尽时的 IAP） |
| **机制介绍** | 不做教程弹窗或帮助页；在用户**恰好经历某机制的瞬间**（首次长按灵器、首次 Seeking、首次打开日记、精力首次低于阈值、首次晚安等）以**轻量浮层**（小 Kuro + 单句气泡）宣读一句「根据协议第 X 条」式台词，3–5 秒自动或轻触消失，每类仅展示一次；巢穴入口在监护人/进化全屏结尾顺带告知。 |
| **外形与语气** | 深黑、几何体、边缘锐利、浮空；礼貌、冷淡、职业化、可打破第四面墙（如「星辰，你对它的干涉超出了预期」） |
| **库洛语与语音** | 使用「库洛语」gibberish（KuroGibberishGenerator：音节表 + 按 scriptKey 确定性生成）+ 代码合成程序化语音（KuroVoiceSynthesizer：正弦 tone 按音节播放）；无 TTS、无 WAV 资源；overlay 出现时播放、关闭时 stop；气泡主句库洛语、副句中文。 |
| **实现位置** | KuroCharacterView、KuroOverlayView、KuroScripts、KuroTipOverlayView、KuroTipStore、KuroGibberishGenerator、KuroVoiceSynthesizer；Room 左下角巢穴长按召唤行政；监护人/进化/能量为全屏 overlay；机制介绍为轻量 overlay |

---

## 2. 生命周期与阶段

### 2.1 全局阶段（MVP-Phase-Plan）

| Phase | 名称 | 状态 | 说明 |
|-------|------|------|------|
| **Phase I** | Anima (The Conception) | 已实现 | 15 轮营火对话，Orb 视觉，Shadow Analysis |
| **Phase II** | Genesis Transition | 已实现 | 视频 + Cosmic Sneeze，Mobi 具象化 |
| **Phase III** | The Room (The Life Protocol) | 已实现 | First Room，Mobi 与用户语音交互、进化 |

### 2.2 LifeStage 枚举

```
genesis  →  Anima 阶段
newborn  →  Mobi 初生，进入 First Room
child    →  Mobi 成长（预留，当前未单独实现）
```

---

## 3. Mobi 的诞生：Anima 遗忘设定

**核心设定：Mobi 出生时不会有 Anima 阶段的记忆。**

| 设定 | 说明 |
|------|------|
| **遗忘** | Anima 在告别时说「我会忘记这场对话」；Mobi 作为新生存在，不继承 Anima 的会话记忆 |
| **继承** | Mobi 继承的是：**外形 DNA**（眼/耳/身/材质）和**人格基调**（persona），这些由强模型从 transcript 推断，但推断结果是「Mobi 长什么样、性格如何」，而非「Mobi 记得 transcript 里说了什么」 |
| **birthMemories** | 强模型目前会返回 `memories`（1–5 条关键时刻，来自 transcript）。若将其作为「Mobi 记得 Anima 对话」注入 prompt，则违背遗忘设定。**设计决策**：birthMemories 不应以「Mobi 的出生记忆」形式注入；可选方案：(a) 不注入，(b) 仅作后台「用户画像」供 LLM 理解用户，不以「你记得……」形式呈现给 Mobi。 |

**实现影响：**

- 不应将 transcript 或 Anima 对话内容直接注入 Room 的 persona / system prompt
- persona 应为自然语言性格描述（2–4 句），不含「你记得用户说过 X」
- 若使用 birthMemories，应明确其语义为「对用户的了解」而非「Mobi 亲身经历」

---

## 4. Mobi 阶段与成长层级（幼年 / 青年 / 成年）

> **全量交互行为设计**：详见 [Mobi交互行为完整设计](Mobi交互行为完整设计.md)。

根据 MVP 与 LifeStage，Mobi 在 Room 中可区分为**幼年期、青年期、成年期**三成长阶段：

### 4.1 阶段定义（基于用户画像完整度 + LifeStage）

**进化节点由后台用户人格画像的完整程度驱动，三阶段同步、只进不退。** 详见 [Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md)。

| 成长阶段 | LifeStage | 触发条件 | 智能特征 |
|----------|-----------|----------|----------|
| **幼年期** | newborn | 出生即进入 | **本能反应为主**：对声音、触摸、silence 做直接反应；无持久记忆；人格槽由画像驱动开始填充；视觉由 DNA + activityState 驱动。**话术**：铭印数 < 3 时乱码语学说话（动森/模拟人生风格 ba、bo、nyeh 等），随铭印增加过渡到简单中文。 |
| **青年期** | newborn（进化后）→ child | **画像完整度 ≥ 阈值 A**；人格槽由画像驱动 | **习得与偏好**：EverMemOS 记忆注入；人格槽进化；可表达简单偏好；置信度衰减时行为更谨慎，**阶段不退**。**话术**：小孩话（短句、好奇、playful，呀/呢/哇）。 |
| **成年期** | child → adult（待实现） | **画像完整度 ≥ 阈值 B**；只进不退 | **自我叙事与记忆**：跨会话记忆；身份叙事；主动关怀；稳定人格；置信度衰减时话术有感知，阶段不退化。**话术**：正常伙伴语气。 |

### 4.2 智能差异对照

| 能力 | 幼年期 | 青年期 | 成年期 |
|------|--------|--------|--------|
| 语音对话 | ✅ 有 | ✅ 有 | ✅ 有 |
| 话术风格 | 铭印 < 3 乱码语学说话；≥ 3 简单中文 | 小孩话（呀/呢/哇） | 正常伙伴 |
| 视觉反应 | ✅ 本能（口型、眨眼、呼吸）| ✅ + 进化外观 | 更丰富 |
| 触觉反应 | ✅ 戳击、拖拽 | ✅ 同上 | 同上 |
| 记忆 | ❌ 无跨会话 | ⚠️ 简单引用 | 跨会话记忆、身份叙事 |
| 自我描述 | 仅 persona 静态 | persona + 简单状态 | 身份叙事 + 记忆引用 |
| 主动行为 | seeking（铭印<3 乱码语；≥3 简单问候）| seeking（小孩式好奇）| seeking（关心、主动话题）|

---

## 5. 视觉资产与外形

### 5.1 资产清单

**角色形象**：由独立项目「Mobi资产生成」管线生成（portrait_{stage}.png + loop_{stage}_blink.mp4），本仓按[共用文件夹契约](Mobi资产生成系统规格.md)消费；未有时用 MobiPlaceholder 占位。**程序化资产**（方案 B）：

| 资产 | 数量 | 实现 |
|------|------|------|
| **eye_shape** | 16 种 | MobiAssetViews.MobiEyeView |
| **ear_type** | 16 种 | MobiAssetViews.MobiEarOverlayView |
| **body_form** | 16 种 | MobiAssetViews.MobiBodyFormShape |
| **personality_slot（人格槽）** | 人格槽即灵器；灵器瓶身填充由画像完整度（slotProgress）驱动 | SoulVesselView |
| material_id | 4 种 | MobiBodyMaterialView |
| palette_id | 5 种 | MobiPalette |

### 5.2 人格 → 外形映射

人格来自 Anima 阶段的 METADATA_UPDATE（shell_type, personality_base, current_mood 等），由强模型/Gemini 映射到 MobiVisualDNA。详见 [PhaseIII-资产与人格映射表.md](PhaseIII-资产与人格映射表.md)。

---

## 6. 大脑与 DNA 机制

### 6.1 DNA 来源（出生时一次性）

| 路径 | 输入 | 输出 |
|------|------|------|
| **强模型** | 15 轮 transcript | visual_dna, persona, memories |
| **回退** | SoulProfile JSON | MobiVisualDNA |

LLM 从 transcript 或 SoulProfile 推断用户特质，输出互补/共鸣的 Mobi 外形与性格。**无本地人格→外形查表**，全由 LLM 决策。

### 6.2 DNA 传递链

```
GenesisCommitAPI → resolvedVisualDNA → MobiEngine → RoomContainerView → ProceduralMobiView
```

### 6.3 出生后变化（EvolutionManager + 用户画像）

人格槽与进化阶段由**用户画像完整度**驱动；与 EvolutionManager 对接后，interactionCount 等可保留用于展示或降级。**客户端实现**（画像 API/Mock/只进不退/持久化）见 [Mobi进化机制实现说明](Mobi进化机制实现说明.md)；上游设计与契约见 [Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md)、[画像-进化接口契约](画像-进化接口契约.md)。

| 规则 | 条件 | 效果 |
|------|------|------|
| 进化阶段（幼年→青年→成年）| 画像完整度 ≥ 阈值 A / B | 只进不退；人格槽与进化解锁由画像驱动；Soul Vessel（胸前灵器）设计见 [SoulVessel设计规范](SoulVessel设计规范.md) |
| personalitySlotProgress | **画像完整度（各维度置信度）** | 灵器瓶身填充（人格槽进度） |
| colorShift / coffeeCup | 画像驱动下的青年/成年解锁 | 颜色变化、咖啡杯 doodle |

---

## 7. 交互驱动

### 7.1 核心：Doubao 实时语音

| 组件 | 作用 |
|------|------|
| AudioVisualizerService | 麦克风 → 16k PCM → 上行 |
| DoubaoRealtimeService | WebSocket 连接、StartSession、上行/下行 |
| AudioPlayerService | TTS 播放 |
| MobiEngine.activityState | 由 Doubao 事件驱动：listening / speaking / idle |

### 7.2 ActivityState 与视觉

| 状态 | 触发 | 视觉 |
|------|------|------|
| listening | 用户在说 | isListening，发光 |
| speaking | AI 在说 | isSpeaking，口型 |
| idle | 无活动 | 默认 |
| seeking | 沉默 > 15s | triggerProactiveConversation |

### 7.3 人设注入

- **roomSystemPrompt**：含 persona（2–4 句）+ 规则
- **Trojan Horse**：Session 启动后伪用户消息强制注入人设
- **prepareForRoom(personaJSON:)**：进入 Room 前设置

---

## 8. 运动与物理

### 8.1 运动类型与驱动

| 运动 | 驱动 | DNA 参与 |
|------|------|----------|
| 呼吸 | 时间轴 sin | — |
| 口型 | isSpeaking + sin | — |
| 戳击 | onTapGesture | movementResponse, bounciness |
| 拖拽 | DragGesture | — |
| 眼睛朝向 | lookDirection | — |
| 眨眼 | 随机 2–6s | — |
| 视差 | ParallaxMotionService (CoreMotion) | — |

### 8.2 眼睛朝向（当前）

`lookDirection = mobiPosition + mobiLiveTranslation`，即**跟随拖拽**。未使用设备朝向或声源方向。

### 8.3 戳击 DNA 映射

```text
spring response: 0.8 - movementResponse * 0.5
dampingFraction: 1.0 - bounciness * 0.7
```

---

## 9. 学习与记忆

### 9.1 当前学习机制与用户画像

| 类型 | 机制 | 存储 |
|------|------|------|
| Anima 侧写 | UserPsycheModel (warmth/energy/chaos) + METADATA | 内存 → SoulProfile，提交给 LLM |
| **用户人格画像** | **EverMemOS 上游服务**：Anima+Room 对话与行为 → 各维度估计与置信度 | 后台沉淀；驱动人格槽与进化阶段 |
| Room 进化 | EvolutionManager（对接画像后由画像驱动）| UserDefaults + 画像 API |
| 关键词 | scanAndRecordKeywords（如「咖啡」）| keywordMentions |
| birthMemories | 强模型提取 | UserDefaults，**未注入 prompt** |

### 9.2 缺口

- birthMemories 已存储但未注入 Room 对话；且按遗忘设定，其语义需重新定义
- 用户画像上游服务与人格槽/进化对接待实现（后端已实现见 backend/，配置 PROFILE_EVOLUTION_BASE_URL 即可）
- 日记 (fetchYesterdaySummary) 已对接 EverMemOS 检索；无结果或未配置 Key 时回退 mock 文案

---

## 10. Mobi 阶段大脑设计

详见 [Mobi阶段大脑与意识驱动设计.md](Mobi阶段大脑与意识驱动设计.md)。

**概要：**

- **MobiBrainState**：arousal, attention, attachment, curiosity, comfort, energy
- **刺激 → 维度更新**：voice, touch, silence, keywords
- **派生状态**：alert, drowsy, curious, seeking, bonded, startled, content
- **输出**：lookDirection, breathScale, scale, sendTextInstruction
- **与 seeking**：由大脑 driving，替代裸 15s 计时

---

## 11. 自我意识与身份

### 11.1 设计目标（叙事层面）

| 维度 | 说明 |
|------|------|
| 身份连贯 | 「我是 Mobi」，稳定性格 |
| 记忆与过去 | 记得与用户的经历（跨会话）|
| 当前状态 | 能表达「我困了」「我好奇」|
| 反思与偏好 | 「我喜欢你这样戳我」|

### 11.2 实现路径

| 机制 | 说明 |
|------|------|
| 身份叙事 | roomSystemPrompt 中固定「你是 Mobi，从虚空中诞生，由用户塑形」|
| 记忆层 | 跨会话记忆存储与注入（阶段 3）|
| 状态觉察 | MobiBrain 状态 → 自然语言注入 LLM |
| 遗忘设定 | **不注入 Anima 对话内容**；birthMemories 若用，需明确非「第一人称经历」|

---

## 12. 文件索引

| 模块 | 关键文件 |
|------|----------|
| 视觉资产 | MobiAssetViews.swift, ProceduralMobiView.swift；角色图 [Mobi资产生成系统规格](Mobi资产生成系统规格.md) |
| DNA | MobiVisualDNA.swift, MobiPalette.swift |
| 交互 | DoubaoRealtimeService.swift, RoomContainerView.swift |
| 进化 | EvolutionManager.swift, UserEvolutionState |
| 记忆 | MemoryDiaryService.swift, MemoryDiaryView.swift |
| 出生 | GenesisCommitAPI.swift, StrongModelSoulService.swift, GeminiVisualDNAService.swift |
| 人设 | MobiPrompts.swift, MobiEngine.roomPersonaPrompt |
| 文档 | MVP-Phase-Plan.md, Mobi资产生成系统规格.md, Mobi交互行为完整设计.md, Mobi用户画像与进化驱动设计.md, Mobi进化机制实现说明.md, Mobi全栈白皮书.md, PhaseIII-资产与人格映射表.md, Mobi阶段大脑与意识驱动设计.md, 画像-进化接口契约.md |

---

## 13. 待办与缺口

| 序号 | 项 | 说明 |
|------|-----|------|
| 1 | **Anima 遗忘** | 确保 birthMemories 不表述为 Mobi 对 Anima 对话的记忆；或停用 birthMemories |
| 2 | **用户画像与进化** | 以 EverMemOS 为核心的上游画像服务；SoulProfile 为画像 Anima 部分；人格维度、用户倾诉、语言习惯模仿；画像完整度驱动人格槽与进化阶段；只进不退；置信度衰减时行为有感知；详见 [Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md) §9；进度与 MVP-Phase-Plan §7 对齐 |
| 3 | **MobiBrain** | 已实现：6 维度 + decay、刺激注入、lookTarget/seeking、呼吸/startled 接 ProceduralMobiView |
| 4 | **lookDirection** | 由 attention 驱动，而非仅拖拽 |
| 5 | **幼年/青年/成年** | 进化由画像驱动；实现成年期、LifeStage.adult，跨会话记忆与身份叙事；详见 Mobi交互行为完整设计 |
| 6 | **状态觉察注入** | MobiBrain 状态 → LLM prompt/sendTextInstruction |
| 7 | **日记 API** | fetchYesterdaySummary 接真实后端 |

---

## 14. 核心文档关系

本指南与 [MVP-Phase-Plan](MVP-Phase-Plan.md)、[Mobi全栈白皮书](Mobi全栈白皮书.md)、[Mobi交互行为完整设计](Mobi交互行为完整设计.md)、[Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md) 共同构成项目核心文档。交互行为相关以 Mobi交互行为完整设计 为准；进化与人格槽驱动以 Mobi用户画像与进化驱动设计 为准。**施工进度**以 MVP-Phase-Plan §7 与 Mobi用户画像与进化驱动设计 §9 为总表；有修改需及时同步更新。

---

*文档版本：2025-02，依据本对话及 docs 目录整理。*
