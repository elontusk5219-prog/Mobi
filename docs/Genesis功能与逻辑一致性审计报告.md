# Genesis Phase 1 — 功能与逻辑一致性审计报告

基于《Mobi 灵魂铸造协议》与近期架构方案，对工程进行的四维度 + 调试工具审计结果。

---

## 1. 灵魂铸造协议 (Soul Casting Protocol) 审计

### 1.1 实时计算（T/E/S 来源）

| 项目 | 状态 | 说明 |
|------|------|------|
| **warmth (Sentiment)** | ✅ 已通过 | `UserPsycheModel` 使用 `NaturalLanguage.NLTagger(tagSchemes: [.sentimentScore])`，在 `computeWarmthTarget(inputText:)` 中按段落取 sentiment，>0.2→1.0，<-0.2→0.0。 |
| **energy (Length)** | ✅ 已通过 | `computeEnergyTarget` 用文本长度与标点：短句(<30)、含 `!` → 1.0；长句(>80)、含 `...`/`…` → 0.0。 |
| **energy (Pitch)** | ⚠️ 未实现 | 协议 [cite: 31] 提及 Pitch；当前仅基于文本 Length，无音频 pitch 分析。 |
| **chaos (Keywords)** | ✅ 已通过 | `computeChaosTarget` 使用 `chaosIncreaseKeywords` / `chaosDecreaseKeywords` 词集做关键词 delta，再 clamp。 |

**结论**：实时计算除「energy 的 Pitch」外均已按协议实现；Pitch 若需落地需接入音频分析（如 Doubao/VAD 或本地 pitch 检测）。

---

### 1.2 参数映射到 AminaView（颜色、脉动、模糊）

| 项目 | 状态 | 代码位置 |
|------|------|----------|
| **warmth → 颜色** | ✅ 已通过 | `GenesisVisuals.NebulaSoulView.warmthColor` 使用 `psycheModel.warmth`（clamp 0...1）→ `Color.soulWarmth(amount:)`，蓝↔橙。 |
| **energy → 脉动频率** | ✅ 已通过 | `pulseDuration = 1.0 - (e * 0.5)`，与 `effectivePulsePeriod` 参与 Timeline 动画。 |
| **chaos → 模糊度** | ✅ 已通过 | `chaosBlur = 5 + c * 25`，与 `progressionBlur` 组成 `totalBlur` 用于 blob 渲染。 |

**结论**：T/E/S 已正确映射到 Amina（NebulaSoulView）的颜色、脉动周期与模糊半径。

---

### 1.3 7 轮计数与 triggerBirth()

| 项目 | 状态 | 说明 |
|------|------|------|
| **MobiEngine 第 7 次触发 birth** | ✅ 已通过 | `MobiEngine.birthThreshold = 7`，`recordInteraction()` 中 `interactionCount += 1`，`if interactionCount >= birthThreshold { triggerBirth() }`。 |
| **「7 轮」语义** | ⚠️ 需确认 | 当前 **birth 由「点击 Soul」驱动**（`AminaView.onTapGesture` → `viewModel.recordInteraction()` → `engine.recordInteraction()`），即 **7 次点击** 触发 birth。协议若指「第 7 轮对话结束后」触发，则应在 **每轮用户说完话**（listen→thinking，即 `processUserInput`）时调用 `engine.recordInteraction()`，与 `psycheModel.conversationTurn` 对齐。当前未在 `processUserInput` 中调用 `engine.recordInteraction()`。 |

**结论**：7 次「交互」触发 birth 已严格实现；若协议要求为 7 轮「对话」而非 7 次点击，需在 `GenesisViewModel.processUserInput` 中增加 `engine.recordInteraction()` 并确认与 `conversationTurn` 一致。

---

### 1.4 数据安全（T/E/S clamp 0.0~1.0）

| 项目 | 状态 | 代码位置 |
|------|------|----------|
| **UserPsycheModel 写入** | ✅ 已通过 | `warmth`/`energy`/`chaos` setter 内 `let c = min(max(newValue, 0), 1)`。 |
| **UserPsycheModel 计算** | ✅ 已通过 | `computeChaosTarget` 返回 `clamp(target, 0, 1)`。 |
| **GenesisVisuals 使用** | ✅ 已通过 | `warmthColor`/`pulseDuration`/`chaosBlur` 均使用 `min(max(psycheModel.*, 0), 1)` 或等价 guard。 |

**结论**：T/E/S 在写入与使用处均做了 0~1 限制，可防止渲染溢出导致 UI 消失。

---

## 2. 交互逻辑与「初啼」(The First Breath) 审计

### 2.1 启动序列（异步唤醒）

| 项目 | 状态 | 说明 |
|------|------|------|
| **连接成功 → 延时 2–3s → sendWakeUpTrigger** | ✅ 已通过 | `DoubaoRealtimeService` 在 eventId 150（Session Started）时：`connectionOpenTime` 在 WS `didOpen` 时已设；`elapsed = connectionOpenTime.map { Date().timeIntervalSince($0) } ?? 2.0`，`delay = max(0, 2.0 - elapsed)`，`queue.asyncAfter(deadline: .now() + delay)` 后调用 `sendWakeUpTrigger()`，即约 2s 内发送唤醒指令。 |

**结论**：异步唤醒序列已实现（连接成功 → 约 2s 后发 Wake-Up）。

---

### 2.2 首句抢答（AI 主动第一句）

| 项目 | 状态 | 说明 |
|------|------|------|
| **Mobi 在用户说话前先由 AI 发起第一句** | ✅ 已通过 | `sendWakeUpTrigger()` 发送「困惑式提问」系统指令；`GenesisViewModel.isWakingUp` 为 true 时不开麦，`handleWakeUpTransition` 在首次进入 `.speaking` 时置 `isWakingUp = false` 并 `audioVisualizer.startMonitoring()`，实现「AI 先说 → 再开麦」。 |

**结论**：首句抢答逻辑已实现。

---

### 2.3 麦克风锁 (Mic Gate)

| 项目 | 状态 | 说明 |
|------|------|------|
| **activityState == .speaking 时 isInputMuted == true** | ✅ 已通过 | `GenesisViewModel.handleMicGate`：`case .speaking:` 内 `audioVisualizer.isInputMuted = true`；`.listening`/`.idle`/`.seeking` 时置 false。 |
| **状态看门狗：卡在思考/说话 >10s 自动解锁并重置 .idle** | ❌ 未满足 | 当前实现为 **6s**：`releaseMicGateIfStuck()` 中 `Date().timeIntervalSince(entered) > 6`。审计要求为 **10s**。 |

**结论**：Mic 在 speaking 时静音已实现；看门狗超时需从 6s 改为 10s 以符合审计要求。

**建议修改**：`GenesisViewModel.releaseMicGateIfStuck()` 将 `> 6` 改为 `> 10`，并同步注释/打印文案。

---

## 3. 视觉反馈与「吞咽」(The Gulp) 审计

### 3.1 粒子喂食（listen → thinking）

| 项目 | 状态 | 说明 |
|------|------|------|
| **listen → thinking 触发约 50 个粒子飞入核心** | ⚠️ 数量偏差 | 当前为 **30 个粒子**：`GenesisVisuals.ParticleInjectionOverlay.particleCount = 30`。协议描述为「约 50 个」。触发逻辑正确：`handleActivityChange` 在 `previousActivityState == .listening && newState == .thinking` 时置 `shouldTriggerImplosion = true`，`AminaView` 将 `ParticleInjectionOverlay(trigger: viewModel.shouldTriggerImplosion, ...)` 与 `ParticleImplosionOverlay` 一并使用。 |

**结论**：触发时机与逻辑正确；粒子数量为 30，若需严格符合「约 50」可改为 50。

---

### 3.2 吞咽动效（Gulp scaleEffect）

| 项目 | 状态 | 说明 |
|------|------|------|
| **粒子到达中心后核心 scaleEffect(1.2)** | ✅ 已通过 | `GenesisViewModel.handleActivityChange` 在 listen→thinking 时 `asyncAfter` 0.28s 置 `shouldTriggerGulp = true`，约 0.2s 后置 false；`AminaView` 中 `.scaleEffect(viewModel.shouldTriggerGulp ? 1.2 : 1.0)` + `.animation(.easeOut(duration: 0.12), value: viewModel.shouldTriggerGulp)`。 |

**结论**：Gulp 动效已实现。

---

### 3.3 音频避让 (Ducking)

| 项目 | 状态 | 说明 |
|------|------|------|
| **Mobi 说话或聆听时背景音压低到 0.05 以下** | ⚠️ 部分未满足 | 当前：`handleAmbientDucking` 在 `.listening` 时 `duckVolume(to: 0.02, duration: 0.5)` ✅；在 `.speaking`（及 idle/thinking/seeking）时 `duckVolume(to: 0.15, duration: 0.5)` ❌。审计要求「说话或聆听时」均 ≤0.05，故 **speaking 时 0.15 未满足**。 |

**结论**：聆听时避让已满足；说话时需将 duck 目标从 0.15 改为 ≤0.05（如 0.02 或 0.05）。

**建议修改**：`GenesisViewModel.handleAmbientDucking` 中 `.speaking` 分支改为 `duckVolume(to: 0.02, duration: 0.5)`（或 0.05），与 listening 一致。

---

## 4. 角色人设 (Persona Injection) 审计

### 4.1 注入方式与参数

| 项目 | 状态 | 说明 |
|------|------|------|
| **sendStartSession 中 system_prompt** | ✅ 已通过 | `DoubaoRealtimeService.sendStartSession()` 的 `dialogue_config` 含 `"system_prompt": MobiPrompts.aminaSystemPrompt`。 |
| **temperature 0.9** | ✅ 已通过 | 同 config 中 `"temperature": 0.9`。 |
| **连接成功后「特洛伊木马」身份覆盖** | ✅ 已通过 | eventId 150 处理中，若 `!hasInjectedPersona` 则发送隐藏指令（含 `[SYSTEM INSTRUCTION: OVERRIDE...]` + `MobiPrompts.aminaSystemPrompt`），并 `sendText(trojanHorse)`，然后 `hasInjectedPersona = true`。 |

**结论**：人设注入与 temperature、木马兜底均已实现。

---

## 5. 调试工具 (God Mode) 审计

### 5.1 DebugOverlayView 功能清单

| 功能 | 状态 | 说明 |
|------|------|------|
| **T/E/S 三滑块实时调节** | ❌ 未实现 | 当前仅有 State/Stage/Doubao 状态、Force .newborn、Ambient Mood 按钮与 Live Ear；无 warmth/energy/chaos 滑块。 |
| **Force Birth** | ✅ 已通过 | 按钮 "Force .newborn" 调用 `engine.forceEvolve(targetStage: .newborn)`。 |
| **Force Sleep** | ❌ 未实现 | 无「Force Sleep」按钮。若指将 activityState 设为 `.sleeping` 或某「睡眠」态，需在 Engine/ViewModel 暴露并在此处加按钮。 |
| **Reset Engine** | ❌ 未实现 | 无重置引擎（如 interactionCount、lifeStage、断开连接等）的入口。 |

**结论**：仅 Force Birth 已存在；T/E/S 滑块、Force Sleep、Reset Engine 均未在 Debug 中提供。

---

## 6. 汇总：已通过 vs 未实现/Bug

### 已通过（按维度）

- **协议**：warmth/energy(Length)/chaos 实时计算；T/E/S→颜色/脉动/模糊映射；7 次交互触发 birth；T/E/S 全链路 clamp。
- **交互**：异步唤醒（2s 内 Wake-Up）；首句抢答；speaking 时麦克风静音。
- **视觉**：listen→thinking 粒子触发；Gulp scaleEffect(1.2)。
- **人设**：sendStartSession 注入 aminaSystemPrompt + temperature 0.9；150 后木马注入。
- **Debug**：Force .newborn。

### 未实现或存在偏差

| 序号 | 维度 | 项目 | 建议 |
|------|------|------|------|
| 1 | 协议 | energy 未使用 Pitch（仅 Length） | 如需协议完全一致，增加音频 pitch 分析并参与 energy。 |
| 2 | 协议 | 「7 轮」当前为 7 次点击 | 若协议为 7 轮对话，在 `processUserInput` 中调用 `engine.recordInteraction()` 并与 conversationTurn 对齐。 |
| 3 | 交互 | 看门狗 6s 非 10s | `releaseMicGateIfStuck()` 中改为 `> 10`。 |
| 4 | 视觉 | 粒子数为 30 非「约 50」 | 可选：将 `ParticleInjectionOverlay.particleCount` 改为 50。 |
| 5 | 视觉 | speaking 时 duck 0.15 > 0.05 | `handleAmbientDucking` 中 speaking 改为 `duckVolume(to: 0.02 or 0.05)`。 |
| 6 | Debug | 无 T/E/S 滑块 | 在 DebugOverlayView 增加三滑块，绑定到 psycheModel（需传入或从 Engine/Coordinator 获取）。 |
| 7 | Debug | 无 Force Sleep | 增加按钮，例如 `engine.setActivityState(.sleeping)` 或对应 API。 |
| 8 | Debug | 无 Reset Engine | 增加按钮，重置 interactionCount/lifeStage/断开 Doubao 等（需在 Engine/Service 暴露 reset 接口）。 |

---

*审计完成。未修改任何代码，仅做对照与建议。*
