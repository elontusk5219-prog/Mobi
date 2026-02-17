# Project Mobi: MVP Phase Plan (Genesis)

**Target Date:** Feb 17, 2026 (CNY Launch)  
**Core Philosophy:** "Not an App, but a Living Soul."  
**Tech Stack:** iOS (SwiftUI), Doubao Real-time Voice, Gemini (Backend), genesis_transition.mp4

> **维护规则:** 启动新功能实现前必须阅读**三份核心文档**；每次有调整或新想法必须及时更新对应文档。详见 `.cursor/rules/mvp-plan-workflow.mdc`。

**施工进度对齐：** 待办与实现进度以**本表 §7** 与 **[Mobi用户画像与进化驱动设计](docs/Mobi用户画像与进化驱动设计.md) §9** 为总表；其余文档的待办引用或汇总于此，施工时以两处为准并保持同步更新。

### 核心文档（必读）

| 文档 | 路径 | 侧重 |
|------|------|------|
| **MVP-Phase-Plan** | docs/MVP-Phase-Plan.md | 阶段需求、状态、实现位置 |
| **Mobi 完整指南** | docs/Mobi完整指南-关于Mobi的一切.md | Mobi 设计、机制、大脑、自我意识 |
| **全栈白皮书** | docs/Mobi全栈白皮书.md | 全栈架构、数据流、API、技术栈 |
| **Mobi 交互行为完整设计** | docs/Mobi交互行为完整设计.md | Anima/Room 全阶段交互；幼年/青年/成年行为差异 |
| **Mobi 用户画像与进化驱动设计** | docs/Mobi用户画像与进化驱动设计.md | 用户画像上游（EverMemOS 核心）；画像驱动人格槽与进化；只进不退；置信度衰减与行为 |

---

## 1. Architecture: Dual-Brain System

| 模块 | 状态 | 实现位置 |
|------|------|----------|
| Actor (iOS) | 已实现 | DoubaoRealtimeService, GenesisViewModel, AminaFluidView |
| Director (Backend) | 已实现 | GenesisCommitAPI 优先 transcript → StrongModelSoulService；fallback GeminiVisualDNAService；成功返回 DNA+persona+memories |

---

## 2. Phase I: Anima (The Conception)

### 2.1 Visuals

| 需求 | 状态 | 实现 |
|------|------|------|
| 5-layer fluid orb | 已替代 | AminaFluidView: 行星大气 + 破碎日冕 (Cyan/Magenta/Gold) |
| Audio Amplitude -> Shader | 部分 | state == .speaking 驱动 Core Flutter；AudioVisualizerService 提供 normalizedPower |
| Orb expands when User speaks | 已实现 | scaleEffect(listening ? 1.04 : 1.0)，visualScale 随 TTS 变化 |
| 灵性流体微创（弹簧+反射+呼吸+噪点） | 已实现 | interpolatingSpring 插值；onChatContentIncremental 关键词膝跳反射；audioPower 呼吸；noiseGrain 胶片质感 |
| Orb 用户输入驱动（无 METADATA） | 已实现 | processUserInput 驱动 fluidColor/emotionColors；fromWarmthAndTurn；每轮对话有可见形态/颜色变化 |

### 2.2 15-Turn Ethereal Magician Arc (Creation Ritual)

| 需求 | 状态 | 实现 |
|------|------|------|
| 3 阶段弧 | 已实现 | Gathering 1–5, Building 6–12, Farewell 13–15 |
| Magic Trick Protocol | 已实现 | Yes-And / Invisible Lead / Reflection；MobiPrompts |
| Resonance Chamber Tone | 已实现 | 非仆人、非神，神秘、反应式 |
| 噪声防御 | 已实现 | Gibberish/Aggression/Tasks 皆转为 Yes-And 感官 |
| 强制导航 turn prefix | 已实现 | SoulHookController.turnPrefix；先承接再抛出；Reserved 15字+敷衍型→nudge |
| Turn 15 转场 | 已实现 | AI 说完 Turn 15 后开始 Incarnation 转场 |
| Turn 同步与硬性对白保障 | 已实现 | onUserUtterance → processUserInputFromASR；effectiveTurn = min(15, interactionCount+1)；Soul Hook / processLLMResponse 统一使用 effectiveTurn；debug 跳转后告别对白正确触发 |
| 隐形侧写 (Shadow Analysis) | 已替代 | 强模型 transcript 分析：StrongModelSoulService；transcript 收集器；无 transcript 时回退 SoulProfile + GeminiVisualDNAService |

### 2.3 Audio

| 需求 | 状态 | 实现 |
|------|------|------|
| GenesisAmbient 循环 | 已实现 | AmbientSoundService.playGenesisLoop() |
| Turn 13 渐入 Video Audio | 部分 | Turn 11+ ping + reverb 递减 |
| Mood-based DSP | 已实现 | updateMood() |

---

## 3. Phase II: Genesis Transition

### 3.1 当前时间线 (~28.5s)

| 时间 | 视觉 | 音频 |
|------|------|------|
| 0–4s | 太阳耀斑 | GenesisAmbient |
| 4–8s | 消散 → 黑屏 | 同上 |
| 8–10s | 黑屏 (2s) | 10s stopAmbient() |
| 9s | 视频挂载 | - |
| 10–23s | genesis_transition.mp4 | 无独立音轨 |
| 23s | Cosmic Sneeze 开始 | stopAmbient |
| 23–28.5s | Cosmic Sneeze: Void → Spark → Materialization → Sneeze → Connection | sfx_vacuum_silence, sfx_spark_ignite, sfx_shake_fur, sfx_sneeze_cute, sfx_curious_gu, bgm_room_ambience |
| 28.5s | onComplete → Room | - |

### 3.2 Cosmic Sneeze 序列（已实现）

| Phase | 时间 | 视觉 | 音效 / 触觉 |
|-------|------|------|-------------|
| Void | 0s | 100% 黑屏 | sfx_vacuum_silence + UIImpactFeedback(.heavy) |
| Spark | 1.5s | 光罩从中心扩张，揭示房间 | sfx_spark_ignite |
| Materialization | 2s | Mobi scale 0.1→1.1→1.0，-5°~5° 抖动，金粉下落 | sfx_shake_fur |
| Sneeze | 3s | squash y:0.8 → expand y:1.2，鼻部白雾 | sfx_sneeze_cute + UINotificationFeedback(.success) |
| Connection | 4.5s | head tilt 10°，眼神朝向镜头，UI 渐显 | sfx_curious_gu + bgm_room_ambience |

实现位置：IncarnationViewModel, IncarnationSequenceView（IncarnationTransition 在视频结束后切换至 Cosmic Sneeze）。

### 3.3 差异与待办

| 项 | Doc | 当前 | 优先级 |
|----|-----|------|--------|
| 60fps 优化 | TimelineView 同步显示刷新，消散无 blur | 已实现 | - |
| 10s Boom | 0.5s 静默后 Boom | 已实现：stopAmbient 后 0.5s 播 sfx_genesis_boom | - |
| 25s "BER" | 切 Room 时 Pop 声 | 已实现：切 Room 时播 sfx_room_ber | - |
| Room 使用 resolvedMobiConfig | - | 已实现 | - |

---

## 4. Phase III: The Room (The Life Protocol)

| 需求 | 状态 | 实现 |
|------|------|------|
| 出生配置传递 | 已实现 | MobiEngine.resolvedMobiConfig, GenesisCoordinatorView 写入 |
| 3 层 Parallax 背景 | 已实现 | RoomParallaxBackground, ParallaxMotionService (CoreMotion) |
| 昼夜光照 | 已实现 | RoomContainerView 6–18h 暖光 / 18–6h 冷光 overlay |
| Mobi Drop 入场 | 已实现 | spring 动画 + land_thud.mp3 |
| 双眼 + 眨眼 | 已实现 | ProceduralMobiView |
| 呼吸/拖拽/戳击/口型/眼睛追踪 | 已实现 | ProceduralMobiView；softness + dragStretch 参与 squash-stretch 拖拽变形 |
| MobiVisualDNA 材质渲染 | 已实现 | MobiVisualDNA, MobiPalette, ProceduralMobiView (fuzzy_felt/gummy_jelly/matte_clay/smooth_plastic) |
| 16 种眼/耳/身型 | 已实现 | MobiAssetViews: MobiEyeView 16 种、MobiEarOverlayView 16 种、MobiBodyFormShape 16 种；body_shape_factor 细微形变；contentShape/FuzzyOverlay 随 body_form 轮廓；Mobi 无阴影 |
| newborn/child/adult 视觉差异 | 已实现 | ProceduralMobiView：体型比例、stageScale、动画节奏（child 活泼/adult 沉稳）、颜色饱和度；四肢/尾巴/嘴仅 child+ |
| 人格槽（灵器） | 已实现 | 人格槽即灵器；灵器瓶身填充由 slotProgress（用户画像完整度）驱动，长按展示 Soul Sync Rate；见 [SoulVessel设计规范](SoulVessel设计规范.md)、[Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md) |
| Doubao Room 人设注入 | 已实现 | 强模型 persona 自然语言描述 → roomSystemPrompt；无时用 SoulProfile.toJSONSummary() |
| 监听发光 | 已实现 | ProceduralMobiView isListening shadow |
| 进化 Slots (Sprout/Color/咖啡) | 已实现 | EvolutionManager, UserEvolutionState |
| 记忆日记 | 已实现 | MemoryDiaryView, MemoryDiaryService；birthMemories + EverMemOS 检索（fetchYesterdaySummary）|
| Soul Vessel | 已实现（序号 2–5） | 视觉+填充+飞入动效+点击/长按交互、Soul Sync 弹层；满溢进化（裂纹→炸裂→胸口印记）已实现。见 [SoulVessel设计规范](SoulVessel设计规范.md)、[SoulVessel施工顺序表](SoulVessel施工顺序表.md) |
| Voice ID | 依赖后端 | - |
| MobiBrain 大脑驱动 | 已实现 | MobiBrainState + MobiBrain；Room tick 注入刺激；lookTarget/seeking；呼吸/startled 接 ProceduralMobiView；P3-4 状态觉察：seeking 时 sendTextInstruction 注入 stateContextForPrompt（derivedState/arousal/attention） |

### 4.0 Kuro 规则守护者（无 UI 的 UI）

| 需求 | 状态 | 实现 |
|------|------|------|
| Kuro 视觉与剧本 | 已实现 | KuroCharacterView（深黑几何体/锐利描边）、KuroOverlayView（全屏气泡+按钮）、KuroScripts（行政/监护人/进化/能量文案） |
| 巢穴与行政干预 | 已实现 | Room 左下角巢穴长按（0.9s）→ Kuro 行政 overlay；更改档案 → SettingsView；销毁样本 → 二次确认后 resetToGenesis + Doubao 重连 |
| Day 1 监护人协议 | 已实现 | 首次进 Room 未签署时全屏 **Kuro 开场介绍**（welcomeIntro 三屏：这是 Mobi / 教它说话、布置房间 / 麦克风权限）；内嵌权限请求，替代原 guardian 弹窗；GuardianProtocolStore 持久化；协议完成前不启麦 |
| 进化考核 | 已实现 | 人格槽满溢时先弹 Kuro 考核 overlay（认知/情感模块文案 + 进化许可按钮）；用户确认后 vesselOverflowPhase = .cracks 进入裂纹→炸裂→融入序列 |
| 能量与氪金 | 已实现 | EnergyManager（精力 100、按时间/轮次扣减、持久化）；精力耗尽时 Mobi 瘫软 + 自动弹 Kuro 能量账单 overlay；EnergyStoreService（StoreKit 2）购买能量补给；未配置产品时 stub 加满 |
| 库洛语与程序化语音 | 已实现 | KuroGibberishGenerator（音节表、gibberish(for:)/syllables(for:)）、KuroVoiceSynthesizer（AVAudioEngine 按音节合成播放）；KuroOverlayView/KuroTipOverlayView 主句库洛语+副句中文，onAppear 播放、关闭时 stop |
| 开场介绍（星露谷风格）| 已实现 | KuroOverlayMode.welcomeIntro 三屏；KuroScripts.welcomeIntroScreen1/2/permissionPrompt；首次进 Room 替代 guardian |
| Newborn 学说话阶梯 | 已实现 | NewbornSpeechPhase（mute/gibberish/simpleWords）；0 铭印且未听过用户 = mute（TTS 抑制、seeking 抑制）；RepeatWordTracker 重复词检测；ImprintCelebrationOverlay 教会庆祝；ImprintService.storeLearnedWord |
| 房间布置 | 已实现 | FurniturePlacementService、RoomDecorView；5 件家具（水杯/抱枕/画框/地毯/灯）；布置后 Mobi lookAtFurnitureOverride 看向物体；日记「Star 教会了我」最新铭印高亮动画 |

### 4.1 Anima 遗忘设定（设计约束）

**Mobi 出生时不会有 Anima 阶段的记忆。** 详见 [Mobi完整指南](Mobi完整指南-关于Mobi的一切.md#3-mobi-的诞生anima-遗忘设定)。

- birthMemories 来自 transcript，**不应**以「Mobi 记得 Anima 对话」形式注入 Room persona
- persona 仅含性格描述，不含对话内容引用

### 4.2 Mobi 阶段与成长层级（幼年 / 青年 / 成年）

> 详见 [Mobi交互行为完整设计](Mobi交互行为完整设计.md)、[Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md)。

**进化节点由后台用户人格画像的完整程度驱动；人格槽 = 画像完整度的呈现；只进不退；置信度衰减时 Mobi 行为有感知、阶段不退化。**

| 成长阶段 | LifeStage | 触发条件 | 智能特征 |
|----------|-----------|----------|----------|
| **幼年期** | newborn | 出生即进入 | 本能反应；无跨会话记忆；人格槽由画像驱动填充。**学说话阶梯**：0 铭印且未听过用户 = mute（不说话）；听过用户后 = gibberish；重复词 2–3 次可变奖励→教会→铭印庆祝；≥1 铭印简单中文。 |
| **青年期** | newborn（进化后）→ child | **画像完整度 ≥ 阈值 A**；人格槽由画像驱动 | 习得与偏好；EverMemOS 记忆注入；人格槽进化。话术：小孩话（呀/呢/哇）。 |
| **成年期** | child → adult（待实现） | **画像完整度 ≥ 阈值 B**；只进不退 | 跨会话记忆；身份叙事；主动关怀；稳定人格。话术：正常伙伴。 |

---

## 5. Backend

- GenesisCommitAPI: 优先 transcript → StrongModelSoulService；无 transcript 时 SoulProfile → GeminiVisualDNAService；失败 20s Fallback 用 PersonalityToDNAMapper 本地推导 DNA
- **第13轮结束提前 commit**：第14、15轮 Anima 告别时已有缓冲，强模型有充足时间返回
- StrongModelSoulService: 完整 transcript → 接口AI Gemini 2.5 Flash（响应快 5–15s）→ { visual_dna, persona, memories }；确保每位用户 Mobi 独一无二；visual_dna 含 eye_shape(16)/ear_type(16)/body_form(16)
- GeminiVisualDNAService: SoulProfile JSON → LLM → MobiVisualDNA (fallback)；同上支持 ear_type/body_form/16 眼型

---

## 6. 文件索引

| 模块 | 关键文件 |
|------|----------|
| App | MobiApp.swift（每次冷启动 showAuthGate 门控）, DependencyContainer.swift；AuthView（选择/注册 ID） |
| Anima | AminaFluidView, GenesisCoordinatorView, GenesisViewModel |
| 逻辑 | SoulHookController, UserPsycheModel, SoulMetadataParser |
| 过渡 | IncarnationTransitionView, IncarnationViewModel, IncarnationSequenceView, GenesisVideoPlayerView |
| 房间 | RoomContainerView, RoomParallaxBackground, ProceduralMobiView, MobiAssetViews, SoulVesselView（人格槽）, ParallaxMotionService, MemoryDiaryView, CoffeeCupDoodle, EvolutionManager；Kuro：KuroCharacterView, KuroOverlayView, KuroScripts, KuroTipOverlayView, KuroTipStore, KuroGibberishGenerator, KuroVoiceSynthesizer；NewbornSpeechPhase, NewbornSpeechState, RepeatWordTracker, ImprintCelebrationOverlay；FurniturePlacementService, RoomDecorView；EnergyManager, EnergyStoreService（StoreKit 2） |
| DNA 与材质 | MobiVisualDNA, MobiPalette, PersonalityToDNAMapper, GeminiVisualDNAService, StrongModelSoulService |
| 后端 | GenesisCommitAPI |
| 记忆 | MemoryDiaryService.addBirthMemories；EverMemOSClient, EverMemOSMemoryService（Room 对话存储与检索）；BehaviorReportingService（行为上报 EverMemOS）|
| 音频 | AmbientSoundService, AudioPlayerService |

---

## 7. 待办与缺口

**分工表：** 项目经理分工与验收见 [MVP待办清单-分工表](MVP待办清单-分工表.md)（P0～P3 优先级 + 负责人列）。本表保持与分工表对齐。

| 序号 | 项 | 说明 |
|------|-----|------|
| 1 | Anima 遗忘 | 已实现：birthMemories 仅存不注入；StrongModelSoulService persona 指令已加固（禁止「Mobi 记得」「你之前在 Anima 说过」），persona 仅性格描述 |
| 2 | **用户画像与进化** | 客户端进化机制已实现：画像 API 驱动人格槽与进化解锁、只进不退、Mock/降级；详见 [Mobi进化机制实现说明](Mobi进化机制实现说明.md)。上游画像服务、完整度阈值、行为上报等见 [Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md) §9 |
| 3 | MobiBrain | 已实现：6 维度 + decay、刺激注入、lookDirection、seeking、呼吸/startled；P3-4 状态觉察注入 seeking 指令 |
| 4 | **Mobi 行为模块** | 已实现：置信度衰减话术、seeking 按幼年/青年/成年差异化。见 [Mobi行为模块实现说明](Mobi行为模块实现说明.md) |
| 5 | lookDirection | 由 attention 驱动 |
| 6 | Mobi 阶段 2/3 | 进化由画像驱动；child/adult 智能、跨会话记忆。记忆模块：fetchMemoriesForSession(stage) 各阶段均注入 memoryContext（幼年 topK 4、青年/成年 8）；BehaviorReportingService 行为上报。 |
| 7 | 10s Boom / 25s BER | Phase II 音效 |
| 8 | Soul Vessel | 设计见 [SoulVessel设计规范](SoulVessel设计规范.md)；实现见 [SoulVessel施工顺序表](SoulVessel施工顺序表.md)（资产 Agent 视觉+交互，进化 Agent 满溢衔接，画像可选扩展；金句已取消） |
| 9 | 日记 API | 已对接 EverMemOS search；契约与可选扩展见 [日记API契约](日记API契约.md) |
| 10 | **Room 对话逻辑** | 已实现：roomSystemPrompt 按 stage 注入话术（**幼年 newborn**：铭印<3 乱码语学说话、否则简单中文；**青年 child**：小孩话呀/呢/哇；**成年 adult**：正常伙伴）；useNewbornGibberish 由 effectiveStage==.newborn && 铭印数<3 决定；语言习惯注入端（languageHabits）。见 MobiPrompts.roomSystemPrompt、DoubaoRealtimeService.prepareForRoom。 |
| 11 | **每次启动选择 ID 门控** | 已实现：MobiApp 冷启动时 showAuthGate=true，先显示 AuthView；AuthView onAppear 清空当前用户，副标题「每次启动请选择或输入要使用的 ID」；选择/注册后进入对应 ID 的 Genesis 或 Room，避免搞混。 |
| 12 | **Mobi 资产生成管线** | 独立项目「Mobi资产生成」实现；对接方式：共用文件夹（output/{user_id}/）。本仓消费：RoomContainerView 默认 MobiPlaceholder；待管线产出后从共享根读 portrait_{stage}.png、loop_{stage}_blink.mp4。**房间与 Kuro**：generate_room_kuro.py 产出 room/HomeBackground.png、kuro/KuroCharacter.png；sync 脚本与 Build Phase 已接入；RoomContainerView 与 KuroCharacterView 有图则用图、无则程序化。规格见 [Mobi资产生成系统规格](Mobi资产生成系统规格.md)、[Mobi预生成资产清单与提示词](Mobi预生成资产清单与提示词.md)。 |
