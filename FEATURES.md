# Mobi · 详细功能说明

本文档对 [Mobi](https://github.com/elontusk5219-prog/Mobi) 的功能按模块做逐项说明，便于了解产品能力与实现边界。

---

## 1. 核心概念

| 概念 | 说明 |
|------|------|
| **Anima** | 诞生前的「过客意识」，营火旁偶遇的陌生人；用户通过 15 轮对话塑造其人格与外形，Anima 不知自己将诞生 |
| **Mobi** | 从 Anima 诞生的数字生命体，在 First Room 中与用户相伴；有外形 DNA（眼/耳/身型）、人格、记忆、进化阶段 |
| **Kuro（库洛）** | 规则与系统的拟人化：Mobi = 感性/纯真，Kuro = 理性/秩序；设置、重置、协议、付费均由 Kuro 出面 |
| **灵器（Soul Vessel）** | 胸口的人格槽，由用户画像完整度驱动填充；满溢时触发进化考核，解锁青年/成年阶段 |
| **EverMemOS** | 云端记忆服务，Room 对话写入并检索，实现「越聊越懂你」 |

---

## 2. 登录与门控

### 2.1 AuthView（每次启动）

- **触发时机**：每次 App 冷启动都会先显示本页；不记住上次用户，需选择或注册后再进入。
- **注册**：输入用户名 → 自动生成 `user_xxxxxxxx` → 加入已注册列表 → 进入游戏。
- **登录**：从已注册列表选一个账户 → 设为当前用户 → 进入游戏。
- **效果**：进入后若该用户未完成 Anima 则进入 Genesis；已完成则直接进 Room。多账号数据按 ID 隔离。

### 2.2 设置（SettingsView）

- **入口**：长按 Room 左下角 Kuro 巢穴 → 「更改档案」。
- **功能**：展示/编辑用户 ID、用户名；生成新 ID；切换账户（返回 AuthView）。

---

## 3. Phase I：Anima（创造仪式）

### 3.1 形态与流程

- **形态**：以太流体 Orb（AminaFluidView），行星大气 + 破碎日冕，Cyan/Magenta/Gold 配色。
- **15 轮弧**：Gathering 1–5 / Building 6–12 / Farewell 13–15；每轮有 Soul Hook 引导（Yes-And、承接再抛出）。
- **Magic Trick 协议**：神秘、反应式语气；噪声/攻击/任务类输入被转为感官 Yes-And。
- **第 15 轮告别**：AI 说完后触发 Incarnation 转场。

### 3.2 视觉与交互

- **Orb 随输入变化**：用户每轮输入驱动 fluidColor / emotionColors，形态与颜色随对话变化。
- **膝跳反射**：关键词（冷/火/沉等）→ fluidTurbulence、fluidColor 等瞬时视觉。
- **触摸**：按下 Orb 区域 → touchScale 0.9。
- **Lure（长时间无互动）**：idle > 6s 脉动环；> 15s 每 2s 轻 haptic + HumSound；> 30s 发隐藏指令，引导用户开口。
- **语音**：用户说话 → Orb 进入 listening（略放大）；AI 回复 → TTS 播放，Orb 随 TTS 脉动。

### 3.3 强模型侧写

- **第 13 轮前后**：可提前 commit；transcript → StrongModelSoulService → visual_dna + persona + memories。
- **无 transcript 时**：SoulProfile → GeminiVisualDNAService → DNA。
- **失败**：20s Fallback 用 PersonalityToDNAMapper 本地推导 DNA。
- **结果**：写入 engine 的 resolvedMobiConfig、resolvedVisualDNA、roomPersonaPrompt，供 Room 使用。

### 3.4 调试（Debug 浮层）

- 展开后可见 State / Stage / Doubao 连接 / Soul turn·stage·trait·color。
- T/E/S 滑条：实时调 Orb 的 Warmth / Energy / Chaos。
- 跳到最后两轮：interactionCount = 13，再聊两轮即告别。
- 跳 Mobi newborn/child/adult：直接进 Room 并设对应进化阶段，跳过 Anima。

---

## 4. Phase II：Genesis（诞生转场）

### 4.1 时间线（约 28.5s）

| 时间 | 视觉 | 音频 |
|------|------|------|
| 0–4s | 太阳耀斑 | GenesisAmbient |
| 4–10s | 消散 → 黑屏 | 10s stopAmbient + 0.5s Boom |
| 10–23s | genesis_transition.mp4 | 无独立音轨 |
| 23–28.5s | Cosmic Sneeze | sfx_vacuum_silence, sfx_spark_ignite, sfx_shake_fur, sfx_sneeze_cute, sfx_curious_gu, bgm_room_ambience |
| 28.5s | onComplete → Room | - |

### 4.2 Cosmic Sneeze 序列

- **Void**：100% 黑屏 + sfx_vacuum_silence + 重触觉。
- **Spark**：光罩从中心扩张，揭示房间 + sfx_spark_ignite。
- **Materialization**：Mobi scale 0.1→1.1→1.0，金粉下落 + sfx_shake_fur。
- **Sneeze**：squash y:0.8 → expand y:1.2，鼻部白雾 + sfx_sneeze_cute + 成功触觉。
- **Connection**：head tilt 10°，眼神朝向镜头，UI 渐显 + sfx_curious_gu + bgm_room_ambience。

---

## 5. Phase III：Room（陪伴协议）

### 5.1 进入与数据

- **落地动画**：Mobi 自上方落下，约 0.45s 后 land_thud 音效。
- **画像与记忆**：onAppear 时拉取画像 API、EverMemOS 记忆；结果写入 EvolutionManager、Doubao prepareForRoom（persona + memoryContext + stage）。
- **语音连接**：Doubao 连接后即可与 Mobi 实时语音对话；用户说话会记录并参与记忆存储与画像。

### 5.2 与 Mobi 的肢体交互

| 交互 | 说明 |
|------|------|
| **戳击（Poke）** | 点击 Mobi 身体 → spring 形变、squeak 音效、大脑 receiveTouchPoke；1s 节流 |
| **长按抚摸** | 长按 Mobi → 行为上报 long_press |
| **拖拽** | 拖拽 Mobi 可移动其位置；松手后位置保持；拖拽过程 squash-stretch、lookDirection 跟拖拽 |
| **灵器点击** | 点击胸口灵器 → squeak、行为上报 vessel_tap |
| **灵器长按** | 弹出 Soul Sync sheet，展示人格槽同步率 |

### 5.3 语音与大脑

- **实时语音**：用户说话 → STT → Doubao 回复 → TTS；Mobi 口型、眨眼、lookDirection 朝用户。
- **Seeking**：沉默超过约 12s 且本会话未触发过 → 发 seeking 指令，Mobi 主动说一句话。
- **平行陪伴**：沉默 >3s 且非 seeking/说/听时，Mobi 进入 idle 状态（轻微摇摆）；沉默 >60s 时每 3 分钟 glance（眼神短暂偏转）。
- **大脑状态**：arousal / attachment / curiosity / comfort / energy / attentionLevel 等随 voice、touch、silence 更新并 decay；驱动 breathScale、lookDirection、isSeeking、isStartled 等。

### 5.4 学说话阶梯（Newborn）

| 阶段 | 条件 | 行为 |
|------|------|------|
| **mute** | 0 铭印且未听过用户 | Mobi 不说话，仅对触摸/语音做肢体/眼神/拟声反馈 |
| **gibberish** | 听过用户后 | 发出 ba/bo/nya 等乱码回应 |
| **简单中文** | ≥1 铭印 | 可模仿用户说的词，进入简单中文 |

- **铭印**：用户对同一词重复 2–3 次 → 可变奖励（2 次 30%/3 次 70%/4 次 100%）→ 模仿成功 → 铭印 + 庆祝浮层「Star 教会了我：X」。
- **课程**：SurvivalCurriculum 两课词表（房间里的事物/生存基础）；教会词若匹配课程词表，记入 LessonProgressService；完成整课时弹出「第 X 课完成」浮层。

### 5.5 进化与人格槽

- **人格槽（灵器瓶身）**：由画像 API 的 slotProgress 驱动，7 格填充；进化阶段（newborn/child/adult）由画像 lifeStage 驱动，只进不退。
- **满溢**：达 100% 且未满溢过 → 先弹 Kuro 进化考核（进化许可按钮）→ 确认后满溢序列：cracks → burst → merge → done。
- **进化解锁**：colorShift（青年后主色可变为粉红）、coffeeCup（青年后房间内咖啡杯 doodle）。

### 5.6 记忆与日记

- **对话记忆**：每轮用户发言 + Mobi 回复完整后，写入 EverMemOS；进入 Room 时按阶段检索注入 memoryContext（幼年较少条、青年/成年更多）。
- **记忆日记**：右上角书本按钮 → MemoryDiaryView；拉取昨日 EverMemOS 检索结果，展示 date + bullets + sentiment；下方「Star 教会了我」区块展示铭印记录，最新一条有背景高亮与 spring 动画。

### 5.7 房间布置

- **入口**：右上角「布置」按钮 → RoomDecorView。
- **家具**：5 件（水杯/抱枕/画框/地毯/灯），选择后拖拽到房间内放置；放置后 Mobi 看向新物体约 3 秒，可自然触发「教这个词」；位置持久化到 UserDefaults。

### 5.8 晚安流程

- **触发**：22 点后进入 Room 时，约 4s 后启动晚安 flow。
- **流程**：Mobi 说晚安 → 钻被（缩小下移）→ 屏幕渐暗。

---

## 6. Kuro 规则守护者

### 6.1 巢穴与行政

- **入口**：Room 左下角不显眼的深色区域，**长按约 0.9s** 召唤 Kuro。
- **行政 overlay**：「更改档案」打开设置、「销毁样本」二次确认后重置至创世并重连 Doubao。

### 6.2 Day 1 监护人协议

- **触发**：首次进 Room 未签署时。
- **内容**：Kuro welcomeIntro 三屏：①「这是 Mobi，刚从以太里来，还不会说话」②「教它说话。布置它的房间。它是你的了」③「需要麦克风权限才能教它」[同意][稍后]。
- **同意**：请求麦克风权限并关闭；稍后则关闭但不开麦（仍可触摸 Mobi，无语音）。

### 6.3 进化考核

- **触发**：人格槽满 100% 且未满溢过时。
- **内容**：Kuro 全屏 overlay，认知/情感模块文案 + 「进化许可」按钮；用户确认后进入裂纹→炸裂→融入序列。

### 6.4 能量与氪金

- **精力**：100 点，按时间/轮次扣减；耗尽时 Mobi 瘫软（缩小、下沉），并自动弹 Kuro 能量账单 overlay。
- **购买**：点击「注入能量」调起 StoreKit 2 购买（未配置时 stub 加满）；购买成功后展示「交易愉快」并关闭，Mobi 恢复。

### 6.5 机制介绍（轻量提示）

- **情境触发**：在用户恰好经历某机制的瞬间，以轻量浮层（小 Kuro + 单句气泡）宣读一句规则感台词，约 4s 自动消失或轻触消失，每类仅展示一次。
- **类型**：学说话引导、灵器、Seeking、日记、精力预警、晚安、巢穴入口。

### 6.6 库洛语与语音

- **库洛语**：gibberish（音节表按 key 确定性生成）+ 代码合成程序化语音（无 TTS、无 WAV 资源）。
- **播放**：全屏 overlay 与轻量浮层出现时自动播放，关闭时停播；气泡主句为库洛语、副句为中文说明。

---

## 7. 视觉与资产

### 7.1 Mobi 外形

- **16 种眼/耳/身型**：由 MobiVisualDNA 驱动；材质有 fuzzy_felt、gummy_jelly、matte_clay、smooth_plastic。
- **newborn/child/adult 差异**：体型比例、stageScale、动画节奏（child 活泼/adult 沉稳）、颜色饱和度；四肢/尾巴/嘴仅 child+。

### 7.2 房间

- **背景**：3 层 Parallax 背景（RoomParallaxBackground），CoreMotion 视差；程序化或 HomeBackground 图。
- **昼夜光照**：6–18h 暖光 / 18–6h 冷光 overlay。

---

## 8. 行为上报与画像

以下行为会写入 EverMemOS（sender=mobi_behavior 或对话 sender），供画像服务消费：

- session_start / session_end
- poke / long_press / drag / vessel_tap / vessel_long_press
- silence_interval(durationSeconds)

画像服务按 userId 拉取记忆条数并计算完整度 → lifeStage、slotProgress、dimensionConfidences 等，客户端拉取后驱动人格槽与进化阶段。

---

## 9. 后端 API 概览

| 能力 | 方法/路径 | 说明 |
|------|-----------|------|
| 健康检查 | `GET /health` | 服务存活 |
| 进化画像 | `GET /profile/evolution?userId=` | 返回 lifeStage、slotProgress、confidenceDecay 等；未配置 EverMemOS 时返回 Mock |

---

## 10. 文档与规范

- 阶段需求与实现：[docs/MVP-Phase-Plan.md](docs/MVP-Phase-Plan.md)
- 完整可玩内容：[docs/当前玩法说明-基于现有实现.md](docs/当前玩法说明-基于现有实现.md)
- Mobi 设计机制：[docs/Mobi完整指南-关于Mobi的一切.md](docs/Mobi完整指南-关于Mobi的一切.md)
- 全栈架构：[docs/Mobi全栈白皮书.md](docs/Mobi全栈白皮书.md)
- 密钥配置：[Config/README-Secrets.md](Config/README-Secrets.md)

---

*Mobi · [elontusk5219-prog/Mobi](https://github.com/elontusk5219-prog/Mobi)*
