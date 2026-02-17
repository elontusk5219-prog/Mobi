# Mobi 进化机制实现说明

**文档用途：** 记录进化模块的**所有情况与分支**（画像 API 成功/失败/Mock/降级、只进不退、持久化、UI 来源）。实现与契约见 [画像-进化接口契约](画像-进化接口契约.md)、[Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md)。

**维护：** 进化机制负责人；实现或分支变更时同步更新。

---

## 1. 数据流总览

```
Room onAppear
    → EvolutionProfileService.fetch()
        ├─ 已配置 PROFILE_EVOLUTION_BASE_URL 且请求 200 → 返回 API 响应
        └─ 未配置 / 请求失败 / 非 200 → 返回契约 Mock（§5.1）
    → EvolutionManager.applyProfileResponse(response)
        └─ 只进不退：仅当 serverStage.evolutionOrder >= localOrder 时更新缓存并持久化
    → UI 读取 EvolutionManager.personalitySlotProgress / effectiveStage / hasUnlocked / confidenceDecay
        ├─ 有缓存 → 用缓存
        └─ 无缓存 → 降级：slotProgress = interactionCount/10，stage = currentStage，unlocked = state
```

---

## 2. 情况分支说明

### 2.1 画像 API 请求

| 情况 | 条件 | 行为 | 产出 |
|------|------|------|------|
| **未配置 baseURL** | `Secrets.profileEvolutionBaseURL` 为空或仅空白 | 不发起请求，直接返回 **Mock 响应**（契约 §5.1） | `EvolutionProfileResponse(lifeStage: "newborn", slotProgress: 0.2, …)` |
| **URL 非法** | `baseURL + "/profile/evolution"` 无法构造为 `URL` | 同上，返回 Mock | 同上 |
| **请求超时/网络错误** | `session.data(for:)` 抛错 | catch 后返回 Mock | 同上 |
| **HTTP 非 200** | `response.statusCode != 200` | 返回 Mock | 同上 |
| **响应体解析失败** | `JSONDecoder().decode` 抛错 | 返回 Mock | 同上 |
| **成功** | 200 且解析成功 | 返回解码后的 `EvolutionProfileResponse` | 服务端真实数据 |

**实现位置：** [EvolutionProfileService.swift](../Mobi/Services/Network/EvolutionProfileService.swift) 的 `fetch()`。

---

### 2.2 只进不退（applyProfileResponse）

| 情况 | 条件 | 行为 |
|------|------|------|
| **服务端阶段 ≥ 本地** | `serverStage.evolutionOrder >= (cachedProfile?.parsedStage() ?? currentStage).evolutionOrder` | 更新 `cachedProfile`（lifeStage、slotProgress、unlockedFeatures、confidenceDecay），持久化，并更新 `currentStage`、`confidenceDecay` |
| **服务端阶段 < 本地** | 上述为 false（正常情况不应出现，服务端保证不回退） | **不更新**缓存与 currentStage，保留本地状态 |

**阶段顺序：** `genesis = -1`，`newborn = 0`，`child = 1`，`adult = 2`。见 [EvolutionProfileResponse.swift](../Mobi/Services/Data/EvolutionProfileResponse.swift) 的 `LifeStage.evolutionOrder`。

**完整度推导 fallback（P1-2）：** 当 API 返回的 `lifeStage` 为空时，用 `completeness` 与阈值 A=0.5、B=0.8 推导阶段（≥B→adult，≥A→child，否则 newborn），并写入缓存；取值与策略见 [Mobi用户画像与进化驱动设计 §4.1a](Mobi用户画像与进化驱动设计.md#41a-完整度聚合与阈值-abp1-2)。

**实现位置：** [EvolutionManager.swift](../Mobi/Services/Data/EvolutionManager.swift) 的 `applyProfileResponse(_:)`；[EvolutionProfileResponse.swift](../Mobi/Services/Data/EvolutionProfileResponse.swift) 的 `derivedLifeStageFromCompleteness(thresholdA:thresholdB:)`。

---

### 2.3 持久化与缓存

| 键 | 内容 | 写入时机 | 读取时机 |
|----|------|----------|----------|
| `mobi.userEvolutionState` | `UserEvolutionState`（interactionCount、intimacyLevel、unlockedFeatures、keywordMentions） | `recordRoomInteraction`、`updateIntimacy`、`scanAndRecordKeywords`、`evaluateTriggers` 后 | init 时 `loadState()` |
| `mobi.evolutionProfileCache` | `CachedEvolutionProfile`（lifeStageRaw、slotProgress、unlockedFeatures、confidenceDecay） | `applyProfileResponse` 中仅当只进不退通过时 | init 时 `loadCachedProfile()` |

**清除缓存：** 仅当 `forceEvolve(targetStage: .genesis)`（如 Debug 系统重置）时清除 `cachedProfile` 并删除 `mobi.evolutionProfileCache`。

---

### 2.4 UI 与调用方使用的数据来源

| 数据 | 有缓存时 | 无缓存时（降级） |
|------|----------|------------------|
| **进化阶段** | `cachedProfile.parsedStage()`（newborn/child/adult） | `currentStage`（由 `setStage`/`forceEvolve` 设定，如 triggerBirth 的 newborn） |
| **人格槽进度（灵器 fillProgress）** | `cachedProfile.slotProgress`（0.0–1.0） | `min(1.0, Double(state.interactionCount) / 10)`；仅驱动灵器瓶身，不再展示 7 格 |
| **是否解锁某外观** | `cachedProfile.unlockedFeatures.contains(feature.rawValue)`；若列表为空则用 state | `state.unlockedFeatures.contains(feature.rawValue)` |
| **置信度衰减** | `cachedProfile.confidenceDecay` | `false` |

**实现位置：** EvolutionManager 的 `effectiveStage`、`personalitySlotProgress`、`hasUnlocked(_:)`、`confidenceDecay`。

---

### 2.5 Room 进入时的时序

1. **RoomContainerView.onAppear** 内 `Task` 首先执行 `await evolution.fetchAndApplyProfile()`。
2. 随后执行 `EverMemOSMemoryService.fetchMemoriesForSession()` 与 Doubao `prepareForRoom`、`connect`。
3. 因此人格槽与进化解锁在 Room 首帧或首帧后不久即已为「画像结果或 Mock」，避免长时间显示旧本地值。

---

## 3. 与 MobiEngine 的配合

- **MobiEngine.lifeStage**：仍表示「是否已完成诞生」（genesis → newborn），由 `triggerBirth()` 设为 newborn；**不**由画像驱动。
- **EvolutionManager.currentStage / effectiveStage**：表示**成长阶段**（newborn/child/adult），由画像结果或 Mock 驱动，只进不退。
- **triggerBirth()**：调用 `evolutionManager.setStage(.newborn)`，保证进入 Room 后若无缓存时展示为 newborn。
- **resetToGenesis（Debug）**：MobiEngine 与 EvolutionManager 均重置；EvolutionManager 清空画像缓存。

---

## 4. 配置与 Mock

- **画像 API 根地址**：`Secrets.profileEvolutionBaseURL`（环境变量 `PROFILE_EVOLUTION_BASE_URL`）。未配置或空则始终使用 Mock。
- **Mock 内容**：见契约 §5.1 与 [EvolutionProfileService.mockResponse()](../Mobi/Services/Network/EvolutionProfileService.swift)。

---

## 5. 相关文件

| 文件 | 职责 |
|------|------|
| [MobiEnums.swift](../Mobi/Core/MobiEnums.swift) | `LifeStage` 含 genesis/newborn/child/**adult**；`evolutionOrder` 用于只进不退 |
| [EvolutionProfileResponse.swift](../Mobi/Services/Data/EvolutionProfileResponse.swift) | 画像响应模型、`parsedLifeStage()` |
| [EvolutionProfileService.swift](../Mobi/Services/Network/EvolutionProfileService.swift) | GET 画像/进化、未配置或失败返回 Mock |
| [EvolutionManager.swift](../Mobi/Services/Data/EvolutionManager.swift) | 缓存、只进不退、personalitySlotProgress / effectiveStage / hasUnlocked / confidenceDecay |
| [RoomContainerView.swift](../Mobi/Features/Room/Views/RoomContainerView.swift) | onAppear 调用 `fetchAndApplyProfile()`；灵器填充用 `evolution.personalitySlotProgress` |
| [Secrets.swift](../Mobi/Config/Secrets.swift) | `profileEvolutionBaseURL` |

---

## 6. 变更记录

| 日期 | 变更 |
|------|------|
| 2025-02 | 初版：画像驱动、只进不退、Mock/降级、人格槽与 UI 来源、持久化与 genesis 重置。 |
| 2025-02 | 人格槽即灵器：身体上移除 7 格 PersonalitySlotView，人格槽进度仅由灵器瓶身填充展示。 |

---

*文档版本：2025-02，与实现同步。*
