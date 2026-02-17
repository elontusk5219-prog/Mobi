# Mobi 资产生成系统规格

> **正式资产生成管线**：独立项目「Mobi资产生成」实现。本 Mobi 仓仅消费资产，管线产出后按共用文件夹契约对接。

---

## 1. 定位

- **独立项目**：资产生成管线在单独 Cursor 项目「Mobi资产生成」内实现，不在此 Mobi 仓
- **不跑在 iOS**：管线在 Mac/服务器运行
- **MVP 阶段**：预生成一批资产供 App 使用，不实时触发；后续可扩展为 Genesis 完成时触发生成
- **输出**：完整角色图（三阶段）+ 眨眼循环视频，供 Room 展示
- **灵器（Soul Vessel）**：单独做成 iOS 组件叠在角色上，不由本管线生成

---

## 2. 输入

### 2.1 人格画像（Persona）

管线接收以下之一即可推导外观：

| 来源 | 说明 |
|------|------|
| `SoulProfile` 简化版 | `shell_type`, `personality_base`, `current_mood` |
| `MobiVisualDNA` | 完整视觉参数，见下文 |

**SoulProfile 简化字段：**

```json
{
  "shell_type": "resilient | soft | armored",
  "personality_base": "playful | healing | quiet | warm | resilient",
  "current_mood": ""
}
```

**MobiVisualDNA（完整视觉参数）：**

```json
{
  "eye_shape": "round | droopy | line | sharp | gentle | sleepy | dot | star | heart | diamond | crescent | wide | narrow | upturned | curious | sparkle",
  "ear_type": "rabbit | hamster | bear | cat | dog | fox | mouse | pig | owl | panda | sheep | butterfly | leaf | star | floppy | none",
  "body_form": "round | rounded_square | triangular | oval | pear | droplet | bean | cloud | star | heart | pill | potato | bell | mushroom | bubble | blob",
  "mouth_shape": "smile | grin | line | calm | gentle",
  "material_id": "fuzzy_felt | gummy_jelly | matte_clay | smooth_plastic",
  "body_color_hex": "D4C5B0",
  "palette_id": "dusty_rose | sunshine_citrus | deep_ocean | electric_neon | natural_clay"
}
```

人格→资产映射规则见本项目 [`docs/PhaseIII-资产与人格映射表.md`](PhaseIII-资产与人格映射表.md)。

### 2.2 生命阶段

三种阶段需不同视觉：

| 阶段 | 视觉差异 |
|------|----------|
| newborn | 更小、更软、无四肢 |
| child | 中等、短肢、Chiikawa 风 |
| adult | 略大、轮廓更清晰 |

---

## 3. 输出资产清单

### 3.1 必须生成

| 资产 | 格式 | 说明 |
|------|------|------|
| `portrait_newborn.png` | PNG，透明底 | 完整角色正面站立图 |
| `portrait_child.png` | PNG，透明底 | 同上 |
| `portrait_adult.png` | PNG，透明底 | 同上 |
| `loop_newborn_blink.mp4` | MP4，可循环 | 眨眼循环视频 |
| `loop_child_blink.mp4` | MP4，可循环 | 同上 |
| `loop_adult_blink.mp4` | MP4，可循环 | 同上 |

### 3.2 可选扩展

| 资产 | 说明 |
|------|------|
| `loop_*_idle.mp4` | 待机呼吸循环（SVD 或类似） |
| `loop_*_speaking.mp4` | 说话口型循环 |

### 3.3 画风要求

- 厚黑线、平涂色、无渐变
- Chibi 比例、马克笔/蜡笔手绘感
- 完整身体正面站立、透明背景、易抠图

---

## 4. 与 Mobi 客户端对接

### 4.1 当前实现

- **RoomContainerView**（[`Mobi/Features/Room/Views/RoomContainerView.swift`](../Mobi/Features/Room/Views/RoomContainerView.swift)）：
  - `mobiImageName: String?`：Asset Catalog 中的图片名；非空且存在时显示 `Image(name)`，否则回退 `ProceduralMobiView`
  - 当前默认 `"MobiPlaceholder"`（占位图）
- **MobiEngine**：`resolvedMobiConfig`、`resolvedVisualDNA`、`roomPersonaPrompt` 来自 Genesis，Room 读取

### 4.2 对接方式

**方式 D：共用文件夹（选定）**

- 约定共享根路径（默认管线项目的 `output/`，可设 `MOBI_ASSETS_ROOT` 覆盖）
- 管线写入 `{共享根}/{user_id}/`，文件名固定：`portrait_newborn.png`、`portrait_child.png`、`portrait_adult.png`、`loop_newborn_blink.mp4`、`loop_child_blink.mp4`、`loop_adult_blink.mp4`
- 客户端从共享根或同步后的 App 内路径按 `{user_id}/portrait_{stage}.png` 读取
- `user_id` 需与 `UserIdentityService.currentUserId` 一致

**其他方式（可选）**

**方式 A：静态打包**

- 构建时或手动将 `portrait_*.png` 加入 `Mobi/Assets.xcassets/` 对应 imageset
- 通过 `mobiImageName` 切换不同角色图

**方式 B：HTTP + 本地缓存**

- 管线部署为服务，暴露 `GET /assets/{userId}/portrait_{stage}.png` 等
- 客户端新增 `MobiAssetService`：按 userId/stage 请求 URL，缓存到沙盒，返回本地路径
- `RoomContainerView` 扩展：支持 `mobiImageURL: URL?`，用 `AsyncImage` 或缓存路径加载；有 URL 时优先用图，否则用 `mobiImageName` 或 ProceduralMobiView

**方式 C：视频播放**

- 若后续用循环视频替代静态图，需在 Room 中增加 `AVPlayerLayer` / `VideoPlayer` 等组件
- 视频 URL 或本地路径由 `MobiAssetService` 提供

**方式 D：共用文件夹**

- 约定共享根路径（如环境变量 `MOBI_ASSETS_ROOT`）；管线写入 `{共享根}/{user_id}/`，文件名固定（portrait_*.png、loop_*_blink.mp4）
- 客户端从同一根路径读取；若无法直接读（如真机沙盒），则通过 sync 脚本将 `{共享根}/{user_id}/` 拷入 App 内（如 `Mobi/Assets/Generated/{user_id}/` 进 Copy Bundle Resources，或写入 App Documents），运行时从该路径读

### 4.3 建议的 API 契约（若采用方式 B）

```
GET /assets/{user_id}/portrait?stage=newborn|child|adult
  → 302 或 200 返回 PNG

GET /assets/{user_id}/loop?stage=newborn|child|adult&type=blink|idle
  → 302 或 200 返回 MP4
```

或：

```
POST /generate
  Body: { "persona": {...}, "user_id": "..." }
  → 200 { "portrait_newborn": "https://...", "loop_newborn_blink": "https://...", ... }
```

---

## 5. 管线实现（独立项目）

管线在「Mobi资产生成」项目内实现，详见该项目的 README 与实现方案。本仓仅定义契约与消费方式。

### 5.1 流程

```
输入 persona / MobiVisualDNA
  → 人格→prompt 映射（参考 PhaseIII-资产与人格映射表）
  → 文生图 API（如火山 Seedream）生成 portrait_newborn/child/adult
  → 图生视频（本地 SVD 或 PIL 眨眼）生成 loop_*_blink.mp4
  → 输出到目录 或 上传 CDN 返回 URL
```

### 5.2 技术栈建议

- 文生图：火山方舟 doubao-seedream（需满足 2560×1440 最小分辨率）
- 图生视频：Stable Video Diffusion（本地）或 PIL 做眨眼叠加
- 可选：rembg 抠图、PIL 后处理

### 5.3 输出目录结构

```
output/{user_id}/
├── portrait_newborn.png
├── portrait_child.png
├── portrait_adult.png
├── loop_newborn_blink.mp4
├── loop_child_blink.mp4
└── loop_adult_blink.mp4
```

---

## 6. 本项目相关文件

| 文件 | 说明 |
|------|------|
| `Mobi/Features/Room/Views/RoomContainerView.swift` | `mobiImageName` 控制是否用图片展示 Mobi |
| `Mobi/Core/MobiVisualDNA.swift` | 视觉 DNA 结构定义 |
| `Mobi/Services/Data/PersonalityToDNAMapper.swift` | SoulProfile → MobiVisualDNA 映射 |
| `docs/PhaseIII-资产与人格映射表.md` | 人格→资产映射规则 |
| `Mobi/Assets.xcassets/MobiPlaceholder.imageset/` | 当前占位图 |

---

## 7. 验收要点

1. 管线能接收 persona/MobiVisualDNA，输出上述 PNG + MP4
2. 画风符合：厚黑线、平涂、Chibi、透明底
3. 三阶段视觉可区分（newborn 更小/软，child 有短肢，adult 更清晰）
4. 眨眼循环视频可无缝循环
5. 按共用文件夹契约（方式 D）写出 `output/{user_id}/`，客户端从共享根或同步后路径按文件名读取
