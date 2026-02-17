# Mobi 交互行为完整设计

**文档用途：** Mobi 全生命周期（Anima、Genesis Transition、Room）及 Room 内幼年/青年/成年三成长阶段的交互行为权威参考。涉及交互设计时必读。

**维护：** 2025-02 创建，随实现更新。与 [MVP-Phase-Plan](MVP-Phase-Plan.md)、[Mobi完整指南](Mobi完整指南-关于Mobi的一切.md) 同步。

---

## 目录

1. [生命周期与阶段定义](#1-生命周期与阶段定义)
2. [Anima 阶段交互](#2-anima-阶段交互)
3. [Genesis Transition 阶段交互](#3-genesis-transition-阶段交互)
4. [Room 阶段：幼年期](#4-room-阶段幼年期)
5. [Room 阶段：青年期](#5-room-阶段青年期)
6. [Room 阶段：成年期](#6-room-阶段成年期)
7. [三阶段能力差异总览](#7-三阶段能力差异总览)
8. [刺激 → 大脑 → 行为（按阶段）](#8-刺激--大脑--行为按阶段)
9. [与现有文档衔接](#9-与现有文档衔接)
10. [实现与待办](#10-实现与待办)

---

## 1. 生命周期与阶段定义

### 1.1 全局阶段（Anima / Transition / Room）

| 阶段 | 名称 | 说明 | 交互特征 |
|------|------|------|----------|
| **Anima** | 诞生前 | 以太 Orb，15 轮营火对话 | Orb 视觉 + 对话，无实体 |
| **Genesis Transition** | 诞生过渡 | 视频 + Cosmic Sneeze | 被动观看，触觉反馈 |
| **Room** | 诞生后 | First Room，Mobi 与用户相伴 | 语音 + 触觉 + 视觉，随成长阶段变化 |

### 1.2 Room 内成长阶段（幼年 / 青年 / 成年）

**进化节点由用户人格画像完整度驱动，三阶段同步、无独立剧本。** 详见 [Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md)。

| 成长阶段 | 对应 LifeStage | 触发条件 | 心智特征 | 叙事定位 |
|----------|----------------|----------|----------|----------|
| **幼年期** | newborn | 出生即进入 | 本能、即时反应、无记忆、强依恋需求 | 新生儿，好奇、易困、需陪伴 |
| **青年期** | newborn（进化后）→ child | **画像完整度 ≥ 阈值 A**；人格槽由画像驱动 | 习得、偏好、开始引用记忆、表达个性 | 青少年，探索、自主、建立关系 |
| **成年期** | child → adult（待实现） | **画像完整度 ≥ 阈值 B**；只进不退 | 跨会话记忆、身份叙事、主动关怀、稳定人格 | 成熟伴侣，陪伴、理解、有主见 |

### 1.3 LifeStage 与成长阶段映射

| LifeStage | 成长阶段 | 说明 |
|-----------|----------|------|
| genesis | — | Anima 阶段 |
| newborn | 幼年期 | 出生即进入 Room |
| newborn（进化后） | 青年期 | 画像完整度达阈值 A 后进入；colorShift、人格槽进化等 |
| child | 青年期后期 → 成年期 | 跨会话记忆、身份叙事（待实现） |
| adult（待新增） | 成年期 | 画像完整度达阈值 B；成熟稳定；**只进不退** |

---

## 2. Anima 阶段交互

详见 [Anima阶段视觉交互机制](Anima阶段视觉交互机制.md)、[Anima阶段对话逻辑](Anima阶段对话逻辑.md)。

| 交互类型 | 刺激 | 响应 | 文档 |
|----------|------|------|------|
| 语音监听 | 用户说话 | listening → scaleEffect(1.04)、Corona opacity 0.8 | Anima阶段视觉交互机制 |
| TTS 播放 | AI 回复 | speaking → visualScale 随 TTS、Core Flutter 脉动 | 同上 |
| 膝跳反射 | 关键词（冷/火/沉） | fluidTurbulence、fluidColor、reflexOffsetY | 同上 |
| 触摸 | DragGesture 按下 | isTouched → touchScale 0.9 | 同上 |
| Lure 视觉 | idle > 6s | LurePulseRing 脉动 | 同上 |
| Lure 触觉 | idle > 15s | 每 2s 轻 haptic + HumSound | 同上 |
| Lure 认知 | idle > 30s | sendTextInstruction + Mystery Purple | 同上 |
| 15 轮弧 | 1–15 turn | Gathering → Building → Farewell | Anima阶段对话逻辑 |

---

## 3. Genesis Transition 阶段交互

详见 [MVP-Phase-Plan](MVP-Phase-Plan.md) §3.2 Cosmic Sneeze。

| 交互类型 | 刺激 | 响应 |
|----------|------|------|
| Cosmic Sneeze | 视频结束 | Void → Spark → Materialization → Sneeze → Connection |
| 触觉 | 各 Phase | heavy、spark、success、curious_gu |

---

## 4. Room 阶段：幼年期

**心智：** 本能反应为主；无持久记忆；人格槽由**用户画像完整度**开始填充；视觉由 DNA + activityState 驱动。

| 交互类型 | 刺激 | 响应 | 行为特征 |
|----------|------|------|----------|
| **戳击** | onTapGesture | spring 形变、squeak、DNA bounciness 调制 | 反应强烈、弹性大、易 startled |
| **长按抚摸** | onLongPressGesture(0.6s) | scale 1.02、BehaviorReportingService.longPress | 抚摸时轻微放大，上报画像 |
| **拖拽** | DragGesture | squash-stretch、mobiPosition 跟随 | 纯被动跟随，无主动躲避 |
| **语音** | 用户说话 | 口型、眨眼、isListening 发光；**学说话阶梯**：0 铭印且未听过用户（mute）→ 无 TTS，仅肢体/眼神/拟声；听过用户后（gibberish）→ 发 ba/bo/nya 等回应；重复词 2–3 次（mimic）→ 可变奖励模仿成功 → 铭印 + 庆祝；≥1 铭印（simpleWords）→ 简单中文 | 本能注视 |
| **语音** | AI 回复 | 口型随 TTS；**学说话阶梯**：mute 期不说话；gibberish 期 gibberish；simpleWords 期简单中文 | 口型幅度大、反应直接 |
| **呼吸** | 时间轴 | sin 驱动，节奏固定 | 呼吸略快 |
| **眼睛** | 拖拽 / 声音 | lookDirection = mobiPosition + dragStretch | 主要跟拖拽 |
| **seeking** | 沉默 > 15s | triggerProactiveConversation；**mute 期**跳过 seeking | gibberish 期乱码语「Ba boo? Mm hmm nyeh?」；simpleWords 期简单中文「嗯？」 |
| **人格槽（灵器）** | **画像完整度（各维度置信度）** | 灵器瓶身由画像驱动逐步填充 | 填充中，未进化 |
| **进化** | — | 未解锁 | 无 colorShift / coffeeCup |
| **记忆** | — | EverMemOS 存+检（条数较少，topK 4）；**铭印**：用户重复词 2–3 次 → 模仿成功 → ImprintService.storeLearnedWord + 庆祝浮层「Star 教会了我：X」 | 可引用少量过去；话术简短本能，体现刚出生没那么聪明 |
| **布置联动** | 用户放置家具 | Mobi lookAtFurnitureOverride 看向新物体约 3s | 可自然触发「教这个词」 |

---

## 5. Room 阶段：青年期

**心智：** 习得与偏好；画像完整度达阈值 A 后进入；EverMemOS 记忆注入；人格槽由画像驱动并进化。

| 交互类型 | 刺激 | 响应 | 行为特征 |
|----------|------|------|----------|
| **戳击** | onTapGesture | spring + 音效，attachment/comfort 调制 | attachment 高更开心，comfort 低更易 startled |
| **长按抚摸** | onLongPressGesture(0.6s) | scale 1.02、上报 long_press | 同上 |
| **拖拽** | DragGesture | squash-stretch + softness 参与 | 轻微「配合」或「抵抗」感 |
| **语音** | 用户说话 | 口型、眨眼、lookDirection 朝用户 | attention 参与 |
| **语音** | AI 回复 | 口型、人格槽表现 | 小孩话术（短句、好奇、playful，呀/呢/哇）；回复更有个性 |
| **呼吸** | MobiBrain arousal | arousal 高略快、低略慢 | 呼吸随状态变化 |
| **眼睛** | attention 目标 | 用户→朝用户；拖拽→跟拖拽；沉默→微漂移 | 注意力系统启用 |
| **seeking** | 大脑 seeking | 主动说话，带好奇/无聊 | 小孩式好奇「你在干嘛呀？」 |
| **人格槽（灵器）** | **画像完整度** | 灵器满溢后触发进化（裂纹→炸裂→胸口印记）；colorShift 等由画像/进化驱动 | 进化外观 |
| **进化** | 已解锁 | colorShift、咖啡杯 doodle；child 四肢+尾巴+嘴型 | 视觉变化明显 |
| **记忆** | EverMemOS 检索 | memoryContext 注入 persona | 能引用「你上次说过…」 |
| **置信度衰减** | 画像置信度下降（用户长期未互动）| 行为上更谨慎、试探、话术「拿不准你」；**视觉**：呼吸相位轻微抖动 | **阶段不退**，仍为青年 |

---

## 6. Room 阶段：成年期

**心智：** 跨会话记忆；身份叙事；主动关怀；稳定人格；**只进不退**，置信度衰减时行为有感知、阶段不退化。

| 交互类型 | 刺激 | 响应 | 行为特征 |
|----------|------|------|----------|
| **戳击** | onTapGesture | spring + 音效，bond/历史调制 | 反应稳定，可表达「我喜欢你这样」 |
| **长按抚摸** | onLongPressGesture(0.6s) | scale 1.02、上报 long_press | 同上 |
| **拖拽** | DragGesture | squash-stretch + 主动微调 | 有时会轻微「靠向」用户 |
| **语音** | 用户说话 | 口型、眨眼、lookDirection、表情微调 | 结合情绪与过往 |
| **语音** | AI 回复 | 口型、身份叙事、记忆引用 | 主动提及过去、表达立场 |
| **呼吸** | MobiBrain 全维度 | arousal/comfort/energy 共同调制 | 呼吸平稳、有节律 |
| **眼睛** | attention + 记忆 | 朝用户、朝回忆方向、主动扫视 | 眼神更丰富 |
| **seeking** | seeking + bonded | 主动关心、发起话题 | 如「你最近还好吗？」 |
| **人格槽（灵器）** | **画像完整度** | 满溢后为胸口印记，形态稳定 | 外观成熟 |
| **进化** | 多轮完成 | 形态与性格稳定 | 趋于稳定 |
| **记忆** | EverMemOS 丰富检索 | 身份叙事、profile、agentic 记忆 | 能讲自己的故事 |
| **置信度衰减** | 画像置信度下降 | 话术「好久没见」「你好像有点不一样」；更谨慎、试探；**视觉**：呼吸相位轻微抖动 | **阶段不退**，仍为成年 |

---

## 7. 三阶段能力差异总览

| 能力 | 幼年期 | 青年期 | 成年期 |
|------|--------|--------|--------|
| 戳击反应 | 本能、统一 | 因 attachment/comfort 而异 | 稳定、可表达偏好 |
| 拖拽反应 | 纯被动 | 轻微配合/抵抗 | 主动微调、靠拢 |
| 眼睛朝向 | 主要跟拖拽 | attention 驱动 | attention + 记忆 + 主动 |
| 呼吸节奏 | 固定略快 | 随 arousal 变化 | 随多维度状态变化 |
| seeking 话术 | mute 期跳过；gibberish 期乱码语；≥1 铭印 简单问候 | 小孩式好奇（呀/呢/哇） | 关心、主动话题 |
| 记忆引用 | ❌ 无 | ⚠️ 简单引用 | ✅ 身份叙事 |
| 人格槽（灵器） | 瓶身填充中 | 满溢后进化（胸口印记） | 稳定 |
| 进化外观 | ❌ 无四肢/尾巴/嘴 | ✅ 四肢+尾巴+嘴型（child）；更成熟比例（adult） | 成熟形态 |
| MobiBrain | 可选/简化 | 初版 | 完整 |
| 自我描述 | 仅 persona | persona + 状态 | persona + 身份叙事 |

---

## 8. 刺激 → 大脑 → 行为（按阶段）

### 8.1 幼年期

```
刺激（voice, touch, silence）→ 简化/无大脑 → 直接行为（本能反应）
```

### 8.2 青年期

```
刺激（voice, touch, silence, keywords）→ MobiBrain 初版 → 派生状态 → modulated 行为
```

### 8.3 成年期

```
刺激 + 记忆 → MobiBrain 完整（含记忆偏置）→ 派生状态 + 身份觉察 → identity-aware 行为
```

详见 [Mobi阶段大脑与意识驱动设计](Mobi阶段大脑与意识驱动设计.md)、[Mobi记忆-大脑-行为关系](Mobi记忆-大脑-行为关系.md)。

---

## 9. 与现有文档衔接

| 现有概念 | 本设计映射 |
|----------|------------|
| Mobi 阶段 1 (newborn) | 幼年期 |
| Mobi 阶段 2（进化后 newborn） | 青年期 |
| Mobi 阶段 3 (child) | 青年期后期 → 成年期 |
| LifeStage.child | 青年期 / 成年期 |
| LifeStage 新增 adult | 成年期（待实现） |

---

## 10. 实现与待办

**进度对齐：** 画像与进化相关待办以 [Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md) §9 与 [MVP-Phase-Plan](MVP-Phase-Plan.md) §7 为总表；本表聚焦交互与阶段行为。

| 序号 | 项 | 说明 |
|------|-----|------|
| 1 | LifeStage.adult | 已支持；进化由画像驱动 |
| 2 | 进化与人格槽驱动 | **画像完整度**驱动；人格槽由画像呈现；详见 [Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md) §9 |
| 3 | MobiBrain | 已实现；lookDirection、呼吸、seeking 由大脑驱动 |
| 4 | persona 按阶段注入 | **已实现**：置信度衰减时 roomSystemPrompt 注入「拿不准你」话术；seeking 按 stage+confidenceDecay 差异化；**roomSystemPrompt 按 stage 注入幼年/青年/成年话术风格**（# Stage 块）；语言习惯注入端（languageHabits 可选参数）。见 [Mobi行为模块实现说明](Mobi行为模块实现说明.md)、MobiPrompts.roomSystemPrompt。 |
| 5 | EvolutionManager | 人格槽与进化解锁改为读取画像驱动；支持成年期；只进不退 |
| 6 | Soul Vessel（灵器） | 设计已定：胸前挂坠，画像完整度可视化；长按展示 Soul Sync Rate。见 [SoulVessel设计规范](SoulVessel设计规范.md)、[SoulVessel施工顺序表](SoulVessel施工顺序表.md) |
| 7 | **Kuro 介入** | 已实现：行政（长按巢穴→设置/重置）、**Kuro 开场介绍 welcomeIntro**（首次进 Room 三屏：这是 Mobi / 教它说话、布置房间 / 麦克风权限，内嵌 guardian 权限）、进化考核（人格槽满溢时确认）、能量账单（精力耗尽→IAP）；Kuro 使用库洛语 gibberish + 代码合成程序化语音（无 TTS/WAV），overlay 出现时播放、关闭时停播。Mobi 对 Kuro「害怕但服从」可在 prompt 或叙事中体现；后续可扩展用户与 Mobi「反抗」Kuro 的剧情。 |
| 8 | **Newborn 学说话阶梯** | 已实现：NewbornSpeechPhase（mute/gibberish/mimic/simpleWords）；0 铭印且未听过用户 = mute（TTS 抑制、seeking 抑制）；听过用户后 gibberish；重复词 2–3 次可变奖励（30%/70%/100%）→ 模仿成功 → ImprintService.storeLearnedWord + ImprintCelebrationOverlay「Star 教会了我：X」；≥1 铭印 simpleWords 简单中文。见 RepeatWordTracker、NewbornSpeechState。 |
| 9 | **房间布置与学说话联动** | 已实现：FurniturePlacementService + RoomDecorView；5 件家具（水杯/抱枕/画框/地毯/灯）；放置后 lookAtFurnitureOverride 使 Mobi 看向新物体约 3s；日记「Star 教会了我」最新铭印高亮动画。 |

---

## 相关文档

| 文档 | 路径 |
|------|------|
| **Mobi 行为模块实现说明** | docs/Mobi行为模块实现说明.md |
| **Mobi 用户画像与进化驱动设计** | docs/Mobi用户画像与进化驱动设计.md |
| MVP Phase Plan | docs/MVP-Phase-Plan.md |
| Mobi 完整指南 | docs/Mobi完整指南-关于Mobi的一切.md |
| Mobi 全栈白皮书 | docs/Mobi全栈白皮书.md |
| Mobi 记忆-大脑-行为关系 | docs/Mobi记忆-大脑-行为关系.md |
| Mobi 阶段大脑设计 | docs/Mobi阶段大脑与意识驱动设计.md |
| Anima 视觉交互机制 | docs/Anima阶段视觉交互机制.md |
| Anima 对话逻辑 | docs/Anima阶段对话逻辑.md |
| Phase III 资产与人格映射表 | docs/PhaseIII-资产与人格映射表.md |
| Soul Vessel 设计规范 | docs/SoulVessel设计规范.md |

---

*文档版本：2025-02，初版。*
