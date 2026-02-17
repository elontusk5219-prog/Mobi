# Incarnation 序列实现与落地审计

对「Anima 高潮 → 化身过渡 → Mobi 诞生」全链路的需求实现情况与落地方式做逐项审计。

---

## 1. 需求与实现对照

| 需求描述 | 实现状态 | 落地方式 |
|----------|----------|----------|
| **Anima Tail：turnCount ≥ 13 收敛** | ✅ 已实现 | `GenesisViewModel`: `turn >= 13` 时 `triggerConvergence(finalColor)`，锁定 `finalSoulColor` / `cohesivePalette`；`isConverging = true` 后不再往 `emotionColors` 注入新色。 |
| **Anima Tail：13 轮后旋转 5x** | ✅ 已实现 | `convergenceRotationMultiplier`（13+ 为 5.0），`AminaFluidView` 中 `rotationScale = (1 + tension*5) * convergenceRotationMultiplier`。 |
| **Anima Tail：13 轮后 jitter 增强** | ✅ 已实现 | `convergenceJitterScale`（13+ 为 2.0），`AminaFluidView` 中 `jitterX/Y` 乘以该系数。 |
| **触发：turnCount == 15 且最终回复完成时展示过渡** | ✅ 已实现 | `processLLMResponse` 内当 `turn == 15` 时置 `showIncarnationTransition = true`；Coordinator 通过 `onChange(of: viewModel.showIncarnationTransition)` 将 `showSingularityTransition = true`，从而全屏展示 `IncarnationTransitionView`。 |
| **10s 无硬切、TimelineView 驱动** | ✅ 已实现 | 单一时钟 `startTime` + `TimelineView(.animation)` 的 `elapsed` 驱动 Phase 1/2 的数学曲线；Phase 3 在 `elapsed >= 6.5` 时一次触发 `triggerRealityDrop()`，用 `@State` + `withAnimation(.spring(...))` 做「拉回」动画。 |
| **Phase 1 (0–3s)：Warp 隧道，强度 0→2 指数** | ✅ 已实现 | `phase1WarpStrength(elapsed) = 2*(1 - exp(-2.5*elapsed/3))`；2.5s 起 `phase1Opacity` 线性降为 0；Layer C 使用 `zoomWarp` + 球体/径向渐变。 |
| **Phase 2 (3–6.5s)：黑底 + 小剪影，约 30% 高，P4 颗粒/边缘光** | ✅ 已实现 | Layer B：`Color.black` + 成人剪影 `screenHeight*0.3` 高；`NoiseGenerator` 叠加 + `ShaderLibrary.noiseGrain` + 白/灵魂色渐变 + `.shadow` 边缘光；`phase2DriftOffset` 做缓慢漂移。 |
| **Phase 3 (6.5s 起)：成人收缩 1→0、房间 scale 4→1 / blur 50→0、spring 落定** | ✅ 已实现 | `triggerRealityDrop()`：`adultImplosionScale` 1→0（0.4s easeIn）；`roomScale` 4→1、`roomBlur` 50→0、`roomOpacity` 0→1、`layerBOpacity` 1→0 用 `spring(response: 0.6, dampingFraction: 0.7)`。 |
| **ZStack 顺序：A=房间/角色 底，B=宇宙成人 中，C=Warp 顶** | ✅ 已实现 | [IncarnationTransitionView](Mobi/Features/IncarnationTransition/IncarnationTransitionView.swift) 内 ZStack 顺序为 Layer A → Layer B → Layer C。 |
| **颜色收敛：final_soul_color / cohesivePalette** | ✅ 已实现 | `SoulMetadata.finalSoulColor` 解析；ViewModel `triggerConvergence` 生成 `cohesivePalette`；过渡视图与球体均使用 `viewModel.finalSoulColor` / `cohesivePalette`。 |
| **zoomWarp 径向拉伸 Shader** | ✅ 已实现 | [MobiShaders.metal](Mobi/Resources/MobiShaders.metal) 中 `zoomWarp(position, center, strength)`，Layer C 通过 `distortionEffect(ShaderLibrary.zoomWarp(...))` 使用。 |
| **成人剪影占位（无图时）** | ✅ 已实现 | 无 `silhouette_adult` 时使用 `adultSilhouettePlaceholder`（圆头 + 多段 Capsule 身体）。 |
| **房间/卡通图资源占位** | ✅ 已实现 | `HomeBackground` / `CartoonMobi` 缺省时用纯色/圆角矩形 + soulColor。 |

---

## 2. 模块与文件清单

| 模块 | 文件 | 职责 |
|------|------|------|
| 化身过渡视图 | [IncarnationTransitionView.swift](Mobi/Features/IncarnationTransition/IncarnationTransitionView.swift) | 10s 时间轴、Layer A/B/C、Phase 1/2/3 逻辑、triggerRealityDrop |
| Genesis 协调 | [GenesisCoordinatorView.swift](Mobi/Features/Genesis/Views/GenesisCoordinatorView.swift) | 展示 AminaFluidView；`showSingularityTransition` 为 true 时全屏叠 IncarnationTransitionView；由 `shouldTriggerTheSnap` 或 `showIncarnationTransition` 触发 |
| 球体与收敛视觉 | [AminaFluidView.swift](Mobi/Features/Genesis/Views/AminaFluidView.swift) | 收敛时用 cohesivePalette；rotationScale × convergenceRotationMultiplier；jitter × convergenceJitterScale |
| 状态与触发 | [GenesisViewModel.swift](Mobi/Features/Genesis/ViewModels/GenesisViewModel.swift) | turnCount、isConverging、finalSoulColor、cohesivePalette、triggerConvergence；showIncarnationTransition（turn==15 置 true）；convergenceRotationMultiplier / convergenceJitterScale |
| 元数据解析 | [SoulMetadataParser.swift](Mobi/Core/SoulMetadataParser.swift) | SoulMetadata.finalSoulColor（optional），从 JSON `final_soul_color` 解析 |
| 着色器 | [MobiShaders.metal](Mobi/Resources/MobiShaders.metal) | zoomWarp、noiseGrain、rgbSplitGlitch（当前过渡主要用前两者） |
| 噪点图 | [NoiseGenerator.swift](Mobi/Core/NoiseGenerator.swift) | Phase 2 成人剪影上的程序化噪点叠加 |

---

## 3. 时间线与 ZStack 逻辑

- **0–3s（Layer C 可见）**  
  - Warp 强度：`phase1WarpStrength` 指数趋近 2。  
  - 透明度：2.5s 前为 1，2.5–3s 线性降为 0。  
  - 底层已绘制 Layer A/B，但 A 的 `roomOpacity` 为 0，B 的 `phase2Opacity` 在 3s 前为 0。

- **3–6.5s（Layer B 可见）**  
  - `phase2Opacity` 在 3–3.2s 淡入，之后为 1。  
  - 成人剪影：高度 30% 屏高、缓慢漂移、noiseGrain + 噪点图 + 边缘光。  
  - Layer C 已透明，Layer A 仍 opacity 0。

- **6.5s（Phase 3 触发一次）**  
  - `elapsed >= 6.5` 且未触发过时调用 `triggerRealityDrop()`。  
  - 设置初始状态后，用 `withAnimation(.spring(0.6, 0.7))` 将房间 scale/blur/opacity 与 Layer B 整体 opacity 动画到目标；成人用 `withAnimation(.easeIn(0.4))` 将 scale 从 1 到 0。

- **6.5–10s**  
  - 房间由「放大模糊」落定到「正常清晰」；成人收缩消失；Layer B 淡出；10s 调用 `onComplete?()`。

- **ZStack 自底向上**：Layer A（房间+卡通）→ Layer B（黑底+成人）→ Layer C（Warp）。无硬切，仅通过 opacity/scale/blur 与一次 Phase 3 状态切换衔接。

---

## 4. 数据与触发链路

```
LLM 回复带 [METADATA: {"turn": 15, "final_soul_color": "#..."}]
  → processLLMResponse
  → turn >= 13 且未收敛时 triggerConvergence(finalColor)
  → turn == 15 时 showIncarnationTransition = true
  → GenesisCoordinatorView.onChange(showIncarnationTransition)
  → showSingularityTransition = true
  → 全屏展示 IncarnationTransitionView(viewModel: viewModel, onComplete: { finishSnapAndBirth(); onComplete(); hide overlay })
```

- **双触发**：当前过渡可由 `shouldTriggerTheSnap`（interactionCount==14 且 speaking→listening）或 `showIncarnationTransition`（收到 turn==15 的 METADATA）任一路触发，均会置 `showSingularityTransition = true` 并展示同一 IncarnationTransitionView。
- **颜色来源**：过渡内 `soulColor` / `soulPalette` 来自 `viewModel.finalSoulColor`、`viewModel.cohesivePalette`；收敛前有 fallback 默认紫蓝色。

---

## 5. 资源与可选增强

| 资源/项 | 当前处理 | 说明 |
|----------|----------|------|
| `silhouette_adult` | 缺省时用占位人形（圆头+胶囊身体） | 放入 Asset Catalog 后可替换为真实剪影图。 |
| `HomeBackground` | 缺省为 `Color(white: 0.94)` | 房间背景图。 |
| `CartoonMobi` | 缺省为圆角矩形 + soulColor | 卡通 Mobi 角色图。 |
| 程序化音频 | 未接入 IncarnationTransitionView | 若需与 Singularity 一致的 Phase 1/2/3 音效，可在此视图 onAppear/elapsed 中调用 ProceduralSoundEngine。 |
| 触觉 | 未在 6.5s 加 haptic | 若需「拉回」瞬间触觉，可在 `triggerRealityDrop()` 内调用 UIImpactFeedbackGenerator。 |

---

## 6. 结论与建议

- **已落地**：Anima Tail（13 轮收敛、5x 旋转、2x 抖动）、turn 15 触发展示过渡、10s 三阶段（Warp → Cosmic Adult → Reality Drop）、ZStack 分层、zoomWarp/noiseGrain、finalSoulColor/cohesivePalette 全链路、房间/成人/卡通占位与资源名约定，均已在上述文件中实现并可追踪。
- **落地方式**：单一 `TimelineView` + 基于 `elapsed` 的 Phase 1/2 曲线 + Phase 3 一次 `@State` + spring/easeIn 动画，无硬切；触发依赖 ViewModel 的 `showIncarnationTransition` 与 Coordinator 的 `showSingularityTransition`。
- **建议**：  
  1. 在 Asset Catalog 中补充 `silhouette_adult`、`HomeBackground`、`CartoonMobi` 以替换占位。  
  2. 若需与旧版 Singularity 一致的「声+触」体验，在 IncarnationTransitionView 内按 elapsed 接入 ProceduralSoundEngine 与 6.5s 触觉。  
  3. 若希望过渡仅由「第 15 轮回复到达」驱动，可考虑移除或弱化对 `shouldTriggerTheSnap` 的依赖，仅保留 `showIncarnationTransition` 触发。
