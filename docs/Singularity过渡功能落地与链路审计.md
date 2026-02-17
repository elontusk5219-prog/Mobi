# Singularity 过渡功能落地与链路审计

对「Anima → Mobi」10 秒过渡（Luminous Void 白底版 + 程序化音频）的落地情况与整条链路的逻辑完整性做逐项审计。

---

## 1. 已实现模块概览

| 模块 | 文件 | 状态 | 说明 |
|------|------|------|------|
| 过渡视图 | [SingularityTransitionView.swift](Mobi/Features/SingularityTransition/SingularityTransitionView.swift) | ✅ 已实现 | 10s 时间轴、三阶段视觉、触觉、音频触发 |
| 程序化音频 | [ProceduralSoundEngine.swift](Mobi/Services/Hardware/ProceduralSoundEngine.swift) | ✅ 已实现 | AVAudioEngine + SourceNode → LPF → Reverb(plate) → MainMixer |
| 应用入口 | [MobiApp.swift](Mobi/App/MobiApp.swift) | ⚠️ 未接过渡 | 仅 `GenesisCoordinatorView` ↔ `Room` 二分，无过渡层 |
| Genesis 协调 | [GenesisCoordinatorView.swift](Mobi/Features/Genesis/Views/GenesisCoordinatorView.swift) | ⚠️ 未接过渡 | 只展示 AminaView，未在 Snap 时展示 SingularityTransitionView |
| 出生触发 | [AminaView.swift](Mobi/Features/Genesis/Views/AminaView.swift) | ⚠️ 仍为短 Snap | `shouldTriggerTheSnap` 时走 0.5s 坍缩 + 0.3s 白闪 + finishSnapAndBirth，未切到 10s 过渡 |
| Room | [RoomContainerView.swift](Mobi/Features/Room/Views/RoomContainerView.swift) | ⚠️ 占位 | 仅「First Room / Genesis complete.」，无「Mobi 团子落地」等设计 |

---

## 2. SingularityTransitionView 内部逻辑（已完整）

- **背景**：`#F5F5F7`，粒子 [Indigo, Coral, Mint, Cyan]，`.blendMode(.multiply)`，`blur(28)`。
- **Phase 1 (0–3s)**：50 个模糊圆漂移，重叠处变深（水彩感）。
- **Phase 2 (3–7s)**：粒子层 scale 1→0.02、旋转 360°，6.8–7s 纯白 overlay 0→1。
- **Phase 3 (7–10s)**：白 overlay 7–7.8s 淡出，Neumorphic 圆 + 灰色涟漪环，圆 scale 0→1（spring），10s 调用 `onComplete?()`。
- **触觉**：7.0s 静默，7.5s `UIImpactFeedbackGenerator(style: .heavy).impactOccurred()`（仅一次）。
- **音频**：onAppear 创建 `ProceduralSoundEngine()`、`startEngine()`、`triggerPhase1_Nebula()`；elapsed≥3 一次 `triggerPhase2_Rise(4)`；elapsed≥7 一次 `triggerPhase3_Ping()`。
- **防重复**：`hasCompleted`、`haptic75Done`、`hasTriggeredPhase2Audio`、`hasTriggeredPhase3Audio`、`hasStartedPhase3` 保证各事件只触发一次。

结论：**视图与时间轴、触觉、音频的内部控制逻辑完整**，缺的是「何时被展示」与「onComplete 如何驱动出生 + 进 Room」。

---

## 3. ProceduralSoundEngine 内部逻辑（已完整）

- **管线**：SourceNode(renderBlock) → AVAudioUnitEQ(1 band lowPass 4kHz) → AVAudioUnitReverb(plate, wetDryMix 50) → mainMixerNode。
- **状态**：`.silence` / `.nebula`(粉红噪) / `.rising`(200→2000Hz 指数升) / `.ping`(880Hz + 0.5s 衰减)。
- **接口**：`startEngine()`、`triggerPhase1_Nebula()`、`triggerPhase2_Rise(duration:)`、`triggerPhase3_Ping()`（内建 0.1s 静默后 ping）。
- **线程**：主线程调接口并加锁写参数；renderBlock 内仅头尾短暂加锁读写相位/音量/噪声状态，未在循环内加锁；粉红噪用 LCG，无 `Float.random`，满足实时安全。

结论：**引擎与规格一致，且仅在被 SingularityTransitionView 展示时才会被创建与调用**；当前因过渡从未展示，引擎在实际流程中未被使用。

---

## 4. 链路缺口：过渡未接入主流程

当前真实流程为：

```
GenesisCoordinatorView (AminaView)
    → 用户对话至 interactionCount == 14，某轮 speaking→listening 时 ViewModel 置 shouldTriggerTheSnap = true
    → AminaView.onChange(of: shouldTriggerTheSnap)：执行「短 Snap」（0.5s 坍缩 + 白闪 0.3s + SnapHaptic）
    → 约 0.85s 后 viewModel.finishSnapAndBirth()
    → engine.recordInteraction() → interactionCount = 15 → triggerBirth() → lifeStage = .newborn
    → GenesisCoordinatorView.onChange(of: engine.lifeStage) → onComplete()
    → MobiApp 将 showRoom = true → 显示 RoomContainerView + 羽白淡出
```

**缺失环节**：  
在 `shouldTriggerTheSnap == true` 时，**没有**任何地方展示 `SingularityTransitionView`。因此：

- 用户看到的仍是约 0.5s 坍缩 + 0.3s 白闪，然后直接进 Room。
- 10s 过渡动画与程序化音频**从未在主流程中运行**。
- `SingularityTransitionView.onComplete` 的设计（10s 后统一收尾、触发出生、进 Room）没有机会执行。

要「落地」过渡功能，必须把过渡插入上述链路，并让 10s 结束时再执行「出生 + 进 Room」。

---

## 5. 建议的完整链路（接入过渡后）

目标流程应为：

1. **触发条件不变**：`interactionCount == 14` 且某轮 speaking→listening → ViewModel 置 `shouldTriggerTheSnap = true`。
2. **不再在 AminaView 内做短 Snap**：一旦 `shouldTriggerTheSnap == true`，由 **GenesisCoordinatorView**（或上层）**全屏展示 SingularityTransitionView**，可遮盖 AminaView（例如 `.fullScreenCover` 或条件 ZStack），且**不再**在 AminaView 里执行 0.5s 坍缩、白闪和 `finishSnapAndBirth()`。
3. **过渡视图的 onComplete**：在 10s 结束时执行：
   - `viewModel.finishSnapAndBirth()`（即 `engine.recordInteraction()` → 第 15 次 → `triggerBirth()`）；
   - 然后调用当前传给 GenesisCoordinatorView 的 `onComplete()`（即 `showRoom = true`），以便进入 Room。
4. **Room**：继续使用现有 `featherWhiteOpacity` 淡出；若后续要体现「Mobi 团子落地」，再在 RoomContainerView 内增加对应 UI 与动画。

这样，SingularityTransitionView 与 ProceduralSoundEngine 才会真正参与主流程，逻辑闭环。

---

## 6. 具体改动建议（实现完整链路）

| 位置 | 建议改动 |
|------|----------|
| **GenesisCoordinatorView** | 增加 `@State private var showSingularityTransition = false`。当 `viewModel.shouldTriggerTheSnap == true` 时置 `showSingularityTransition = true`（可用 `.onChange(of: viewModel.shouldTriggerTheSnap)`）。Body 中：当 `showSingularityTransition` 为 true 时用 `.fullScreenCover`（或 ZStack 顶层）展示 `SingularityTransitionView(onComplete: { ... })`。 |
| **SingularityTransitionView.onComplete 闭包** | 在 Coordinator 里传入的 onComplete 中：先调用 `viewModel.finishSnapAndBirth()`，再调用原来的 `onComplete()`（即让 MobiApp 执行 `showRoom = true`），最后置 `showSingularityTransition = false` 以关闭 fullScreenCover。 |
| **AminaView** | 当「由 Coordinator 在 Snap 时改为展示过渡」后，可保留 `shouldTriggerTheSnap` 的视觉（如 scale 0.05）仅作为过渡出现前的瞬间反馈，**或**在 Coordinator 一检测到 Snap 就盖住 AminaView，则 AminaView 内对 `shouldTriggerTheSnap` 的 0.5s 坍缩与白闪逻辑可移除或改为不执行 finishSnapAndBirth（由过渡的 onComplete 统一执行）。 |
| **MobiApp** | 无需改分支逻辑；仍为 `if showRoom { Room } else { GenesisCoordinatorView }`。Room 的显示仍由 GenesisCoordinatorView 的 onComplete 驱动。 |

---

## 7. 小结

- **功能实现**：SingularityTransitionView（视觉 + 触觉 + 音频触发）与 ProceduralSoundEngine（管线 + 四状态 + 接口）**均已按 spec 实现且内部逻辑完整**。
- **链路缺口**：过渡**未接入**「Genesis → 出生 → Room」主流程；当前仍为短 Snap 直接触发 `finishSnapAndBirth` 与 `onComplete`，导致 10s 过渡与程序化音频从未被使用。
- **补全方式**：在 GenesisCoordinatorView 中根据 `shouldTriggerTheSnap` 展示 SingularityTransitionView，并在其 onComplete 中依次执行 `finishSnapAndBirth()` 与原有 `onComplete()`，即可形成完整、可落地的 Anima → Mobi 过渡链路。
