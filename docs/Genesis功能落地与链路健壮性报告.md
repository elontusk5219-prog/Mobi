# Genesis Phase 1 — 功能落地与链路健壮性报告

基于当前代码的逐层梳理与链路追踪结果。

---

## 一、架构分层与数据流概览

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: App Entry                                              │
│  MobiApp → DependencyContainer, GenesisCoordinatorView, DebugOverlay │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 2: Genesis 协调层                                          │
│  GenesisCoordinatorView(container, onComplete)                    │
│  - 持有: container, engine(@ObservedObject), viewModel(@StateObject) │
│  - 监听: engine.lifeStage → .newborn 时调用 onComplete()          │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 3: 视图 + ViewModel                                        │
│  AminaView(viewModel) ←→ GenesisViewModel(audioVisualizer, engine) │
│  - 音频 → visualScale / isListening / isThinking / shouldTriggerImplosion │
│  - 点击 → recordInteraction + Haptic + isSoulTouched               │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 4: 引擎与能力层                                            │
│  MobiEngine (lifeStage, activityState, interactionCount, currentTranscript) │
│  EvolutionManager (currentStage, setStage, forceEvolve)           │
│  AudioVisualizerService (normalizedPower), HapticEngine           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、功能落地情况（按需求逐项核对）

### 2.1 入口与依赖注入

| 功能点 | 落地情况 | 说明 |
|--------|----------|------|
| @main 入口 | ✅ 已落地 | `MobiApp.swift` 中 `@main struct MobiApp` |
| 根视图为 Genesis | ✅ 已落地 | `WindowGroup` 内为 `GenesisCoordinatorView`，不是 ContentView |
| 依赖统一入口 | ✅ 已落地 | `DependencyContainer` 提供 `mobiEngine`、`audioVisualizerService`、`evolutionManager` |
| Engine 注入方式 | ✅ 已落地 | Coordinator 内 `ObservedObject(container.mobiEngine)`；Debug 为 `ObservedObject(engine)` 显式传入，无 EnvironmentObject 崩溃风险 |

### 2.2 意识之海背景（ConsciousnessBackgroundView）

| 功能点 | 落地情况 | 说明 |
|--------|----------|------|
| 5 色 blob + 黑底 | ✅ 已落地 | Indigo / Cyan / Purple / Emerald / Void Blue，`GenesisVisuals.SeaBlob` |
| 独立位移动画 | ✅ 已落地 | 每 blob 不同 duration(12~20s)、phaseDelay(0~8s)，`withAnimation.repeatForever(autoreverses: true)` |
| 高模糊 + 性能 | ✅ 已落地 | 容器 `.drawingGroup()` 后 `.blur(radius: 120)` |
| 景深 overlay | ✅ 已落地 | `Color.black.opacity(0.3).ignoresSafeArea()` |
| 比例适配 | ✅ 已落地 | `GeometryReader` 下 size/offset 按 `min(w,h)` 比例计算 |

### 2.3 灵魂实体（PrimordialSoulView）

| 功能点 | 落地情况 | 说明 |
|--------|----------|------|
| 液态光（blur+contrast） | ✅ 已落地 | 3 个 `LiquidOrbCircle` 轨道动画 → `.blur(30)` → `.contrast(20)` → `.colorMultiply(tint)` |
| 呼吸缩放 | ✅ 已落地 | `breathScale` 1.0↔1.1，4s easeInOut repeatForever |
| 点击 Bounce | ✅ 已落地 | `isTouched` → touchScale 0.9 → 0.35s 后回 1.0，并重置 binding |
| 音频驱动 scale | ✅ 已落地 | `scaleEffect(breathScale * touchScale * audioScale)`，audioScale 来自 viewModel.visualScale |
| Agitated（isListening 加速） | ✅ 已落地 | `orbDuration = isListening ? 1.5 : 4.0`，轨道动画随 listening 加速 |
| Thinking 色调 | ✅ 已落地 | `isThinking` 时 `colorMultiply(Color.cyan.opacity(0.4))` |

### 2.4 点击与出生逻辑

| 功能点 | 落地情况 | 说明 |
|--------|----------|------|
| 点击 Soul 触发 | ✅ 已落地 | `PrimordialSoulView.onTapGesture` → isSoulTouched、recordInteraction、playLight |
| 交互计数 | ✅ 已落地 | `MobiEngine.recordInteraction()`，genesis 下 interactionCount += 1 |
| 达到阈值出生 | ✅ 已落地 | `interactionCount >= birthThreshold(5)` 时 `triggerBirth()` |
| 出生同步 Evolution | ✅ 已落地 | `triggerBirth()` 内 `evolutionManager.setStage(.newborn)` |
| 出生后界面跳转 | ⚠️ 仅链路存在 | `GenesisCoordinatorView.onChange(of: engine.lifeStage)` 在 .newborn 时调用 `onComplete()`，但 **MobiApp 传入的 onComplete 为空闭包 `{}`**，故当前无实际跳转（如进入 Room） |

### 2.5 音频与视觉反馈

| 功能点 | 落地情况 | 说明 |
|--------|----------|------|
| 进入 Genesis 即开麦 | ✅ 已落地 | `AminaView.onAppear` → `viewModel.startAudioMonitoring()` |
| 引擎设为 listening | ✅ 已落地 | `startAudioMonitoring()` 内 `engine.setActivityState(.listening)` |
| 音量归一化 0~1 | ✅ 已落地 | `AudioVisualizerService.processBuffer` 中 RMS×8 后 `min(1.0, …)`，主线程更新 `normalizedPower` |
| visualScale 随音量 | ✅ 已落地 | listening 时 `visualScale = 1.0 + 0.8 * normalizedPower` |
| isListening / isThinking 驱动 UI | ✅ 已落地 | Timer 每 0.05s 更新 `isListening = (activityState==.listening && power>0.1)`，`isThinking = (activityState==.thinking)` |
| Listening→Thinking 粒子内聚 | ✅ 已落地 | `handleActivityChange` 检测 `previous==.listening && new==.thinking` 置 `shouldTriggerImplosion = true`，0.6s 后复位；`ParticleImplosionOverlay` 16 粒从边缘飞向中心 |
| 谁设置 .thinking | ❌ 未落地 | 当前**没有任何调用** `engine.setActivityState(.thinking)`，故粒子内聚**不会自动触发**，需后续 VAD/ Doubao 在“静音/一句话结束”时调用 |

### 2.6 调试能力

| 功能点 | 落地情况 | 说明 |
|--------|----------|------|
| Debug 浮层不挡点击 | ✅ 已落地 | `Color.clear.allowsHitTesting(false)` + 仅按钮/文案区域可点 |
| 展开 State/Stage/Force .newborn | ✅ 已落地 | `DebugOverlayView.expandedContent` |
| Live Ear 显示转录 | ✅ 已落地 | 底部 `engine.currentTranscript`，空时显示 "(no input)" |
| currentTranscript 写入方 | ❌ 未落地 | **仅读未写**：无 Doubao/STT 服务对接，需后续在语音流水线中对 `MobiEngine.shared.currentTranscript` 赋值 |

---

## 三、链路健壮性

### 3.1 线程与主线程

| 环节 | 结论 | 说明 |
|------|------|------|
| MobiEngine / EvolutionManager | ✅ 安全 | 均 `@MainActor`，状态仅主线程变更 |
| GenesisViewModel | ✅ 安全 | `@MainActor`，且 `engine`/`audioVisualizer` 的 sink 使用 `receive(on: DispatchQueue.main)` |
| AudioVisualizerService | ✅ 安全 | 在音频线程计算 RMS，通过 `DispatchQueue.main.async` 更新 `normalizedPower` |
| 权限回调 | ✅ 安全 | `requestRecordPermission` 回调内通过 `DispatchQueue.main.async` 调用 `_startEngine()` |

### 3.2 生命周期与泄漏

| 环节 | 结论 | 说明 |
|------|------|------|
| GenesisViewModel 订阅 | ⚠️ 潜在泄漏 | `Timer.publish(...).autoconnect()` 与 `engine`/`audioVisualizer` 的 sink 存入 `cancellables`，但 **ViewModel 无 deinit 或 onDisappear 取消订阅**；若 Coordinator 被替换且 ViewModel 长期存活，Timer 会持续触发。建议：在 ViewModel 中保留 cancellables 并在 deinit 中 cancel，或由外部在不再需要时取消。 |
| SeaBlob / LiquidOrb 动画 | ✅ 可接受 | 使用 SwiftUI `withAnimation.repeatForever`，视图销毁时随视图树释放 |

### 3.3 边界与失败路径

| 环节 | 结论 | 说明 |
|------|------|------|
| 麦克风权限拒绝 | ⚠️ 无反馈 | `requestRecordPermission` 若 denied，`_startEngine()` 不执行，`normalizedPower` 恒为 0，**用户无提示**。建议：增加 `@Published var permissionDenied: Bool` 或类似状态，UI 提示授权。 |
| 音频引擎启动失败 | ⚠️ 静默 | `_startEngine()` 中 `engine.start()` 若抛错，仅 `removeTap(onBus: 0)`，**无日志/状态/UI**。建议：至少打日志或更新错误状态。 |
| 无可用输入格式 | ✅ 已防护 | `format.channelCount > 0, format.sampleRate > 0` 校验后 return，避免无效 tap。 |
| recordInteraction 非 Genesis | ✅ 已防护 | `guard lifeStage == .genesis`，避免重复计数。 |
| triggerBirth 非 Genesis | ✅ 已防护 | `guard lifeStage == .genesis`，避免重复出生。 |

### 3.4 数据一致性

| 环节 | 结论 | 说明 |
|------|------|------|
| lifeStage 与 currentStage | ✅ 一致 | `triggerBirth()` 与 `forceEvolve()` 同时更新 Engine 与 EvolutionManager。 |
| previousActivityState 初值 | ✅ 正确 | `idle`，首次进入 listening 不会误判为 listening→thinking。 |
| shouldTriggerImplosion 复位 | ✅ 正确 | 0.6s 后置 false，避免重复触发；粒子动画约 0.45s，时序合理。 |

### 3.5 视图与引用

| 环节 | 结论 | 说明 |
|------|------|------|
| container 与 engine 单例 | ✅ 一致 | `DependencyContainer` 使用 `MobiEngine.shared`，Coordinator 与 Debug 使用同一实例。 |
| ViewModel 与 Engine 引用 | ✅ 一致 | ViewModel 持有 container 传入的 `engine`，即同一 `MobiEngine.shared`。 |
| DebugOverlayView 注入 | ✅ 安全 | 显式 `DebugOverlayView(engine: container.mobiEngine)`，无 EnvironmentObject 未注入风险。 |

---

## 四、总结表

| 类别 | 已落地 | 部分/待补 | 未落地 |
|------|--------|-----------|--------|
| 入口与依赖 | 4 | 0 | 0 |
| 意识之海背景 | 5 | 0 | 0 |
| 灵魂实体与动效 | 6 | 0 | 0 |
| 点击与出生 | 4 | 1（出生后跳转） | 0 |
| 音频与视觉 | 5 | 0 | 1（.thinking 未设置） |
| 调试 | 3 | 0 | 1（currentTranscript 未写入） |
| 线程安全 | 4 | 0 | 0 |
| 生命周期/边界 | 2 | 2（Timer 取消、权限/引擎失败反馈） | 0 |

**结论：**

- **功能落地**：Genesis 展示、背景、灵魂液态光、呼吸/点击/音频缩放、 listening 状态与 Agitated/Thinking 视觉、粒子内聚逻辑、调试浮层与 Live Ear **均已实现**。当前缺口为：**无人调用 `setActivityState(.thinking)`**（粒子内聚不会自动出现）、**无人写入 `currentTranscript`**（Live Ear 恒为 "(no input)"）、**onComplete 为空**（出生后不跳转）。
- **链路健壮性**：主线程与数据一致性良好；建议补充：ViewModel 订阅（含 Timer）的取消、麦克风权限拒绝与引擎启动失败的反馈或日志。

以上为基于当前代码的**分层报告**，可直接用于评审与后续迭代（VAD/Doubao 对接、Room 跳转、错误态与生命周期清理）。
