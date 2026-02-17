# Phase III: 资产与人格映射表（方案 B · 纯 SwiftUI）

**策略**：所有 Mobi 视觉资产由 SwiftUI 代码实现（Shape、Path、Gradient），无 SVG/静态图依赖。人格侧写来自 Anima 对话的 Shadow Analysis，映射到 MobiVisualDNA 参数。

---

## 1. 人格输入维度

| 来源 | 字段 | 取值 |
|------|------|------|
| METADATA_UPDATE | `shell_type` | Armored \| Soft \| Resilient |
| METADATA_UPDATE | `personality_base` | Healing \| Playful \| Quiet \| Resilient \| Warm |
| METADATA_UPDATE | `current_mood` | Aggressive \| Playful \| Tired \| Defensive \| Warm \| Cold |
| METADATA_UPDATE | `energy_level` | High \| Low |
| METADATA_UPDATE | `openness` | High \| Low |
| METADATA_UPDATE | `communication_style` | Direct \| Evasive \| Warm \| Blunt |
| METADATA_UPDATE | `color_id` | dusty_rose \| sunshine_citrus \| deep_ocean \| electric_neon \| natural_clay |
| METADATA_UPDATE | `energy_tag` | high \| low |
| METADATA_UPDATE | `intimacy_tag` | close \| distant |

---

## 2. Mobi 资产输出维度（MobiVisualDNA）

| 资产 | 类型 | 取值范围 | 实现方式 |
|------|------|----------|----------|
| **eye_shape** | 眼型（16 种） | 见 3.3 | SwiftUI EyeView 变体 |
| **ear_type** | 耳朵（16 种） | 见 3.3b | SwiftUI EarShape 变体，贴于头顶 |
| **body_form** | 身体形状（16 种） | 见 3.3c | 身体基底 Shape |
| **personality_slot** | 人格槽（配件） | 见第 5 节 | 花纹/挂件/装饰，长在 Mobi 身上 |
| eye_scale | 眼大小 | 0.5–1.5 | scaleEffect |
| eye_spacing | 眼间距 | 0.0–1.0 | HStack spacing 系数 |
| fuzziness | 毛茸茸度 | 0.0–1.0 | FuzzyOverlayView 开关/强度 |
| blush_opacity | 腮红 | 0.0–1.0 | Ellipse fill opacity |
| material_id | 材质 | fuzzy_felt \| gummy_jelly \| matte_clay \| smooth_plastic | MobiBodyMaterialView |
| palette_id | 配色 | dusty_rose \| sunshine_citrus \| deep_ocean \| electric_neon \| natural_clay | MobiPalette |
| body_color_hex | 身体主色 | 6 位 hex | 材质填充 |
| movement_response | 响应速度 | 0.1–0.9 | 戳击 spring response |
| bounciness | 弹性 | 0.0–0.8 | 戳击 spring damping |
| softness | 柔软度 | 0.0–1.0 | 未来 squash-stretch |
| body_shape_factor | 身形比例 | 0.0(圆)–1.0(梯形) | 与 body_form 配合 |
| mouth_shape | 嘴型（性格映射） | smile \| grin \| line \| calm \| gentle | MobiMouthView；child/adult 阶段渲染 |

---

## 3. 核心映射：shell_type + personality_base → 资产

### 3.1 材质 material_id

| shell_type | personality_base | material_id |
|------------|------------------|-------------|
| Armored | * | matte_clay |
| Armored | Quiet | matte_clay |
| Soft | * | fuzzy_felt |
| Soft | Healing | fuzzy_felt |
| Resilient | * | gummy_jelly 或 smooth_plastic |
| Resilient | Playful | gummy_jelly |
| Resilient | Warm | smooth_plastic |
| * | Quiet | matte_clay |
| * | Healing | fuzzy_felt |
| * | Playful | gummy_jelly |

**优先级**：shell_type 主导；personality_base 为 Healing/Playful/Quiet 时覆盖。

---

### 3.2 配色 palette_id

| 人格 / 情绪倾向 | palette_id |
|-----------------|------------|
| Warm / 暖色氛围 | dusty_rose |
| 高能量 / 活泼 | sunshine_citrus |
| 内敛 / 冷静 | deep_ocean |
| 强烈对比 / 鲜明 | electric_neon |
| 默认 / 自然 | natural_clay |
| color_id（METADATA 直接指定） | 优先使用 |

---

### 3.3 眼型 eye_shape（16 种）

| # | eye_shape | 描述 | 形状 |
|---|-----------|------|------|
| 1 | round | 圆眼 | Circle 瞳孔 + 高光 |
| 2 | droopy | 下垂眼 | Ellipse 扁长略下垂 |
| 3 | line | 线眼 | Capsule 细长 |
| 4 | sharp | 锐利眼 | 略尖 Ellipse，棱角感 |
| 5 | gentle | 柔和眼 | 大圆软边 |
| 6 | sleepy | 困倦眼 | 半睁 Ellipse，上缘平 |
| 7 | dot | 点眼 | 小圆点，极简 |
| 8 | star | 星眼 | 五角星或闪烁形 |
| 9 | heart | 心形眼 | 心形轮廓 |
| 10 | diamond | 菱形眼 | 菱形/钻石形 |
| 11 | crescent | 月牙眼 | 弯月形 |
| 12 | wide | 大睁眼 | 大圆，惊讶感 |
| 13 | narrow | 狭长眼 | 细长 Ellipse |
| 14 | upturned | 上扬眼 | 外角上翘 |
| 15 | curious | 好奇眼 | 略倾斜，探究感 |
| 16 | sparkle | 闪亮眼 | 圆+星形高光 |

**人格 → 眼型映射**：personality_base + current_mood 组合映射到 0–15 索引，或 LLM 直接输出 eye_shape 枚举。

### 3.3a 嘴型 mouth_shape（性格映射）

| personality_base | mouth_shape | 形状描述 |
|------------------|-------------|----------|
| Healing | smile | 上扬弧线 |
| Playful | grin | 大弧形张开 |
| Quiet | line | 一字抿嘴 |
| Resilient | calm | 直线略弯 |
| Warm | gentle | 柔和小弧 |
| 默认 | gentle | 同上 |

仅 child/adult 阶段渲染；newborn 无嘴巴。

---

### 3.3b 耳朵 ear_type（16 种 · Chiikawa 风）

| # | ear_type | 描述 | 形态 |
|---|----------|------|------|
| 1 | rabbit | 长耳竖立 | 细长 Ellipse 向上 |
| 2 | hamster | 圆耳贴两侧 | 小圆贴服 |
| 3 | bear | 圆耳 | 中等圆润 |
| 4 | cat | 尖耳 | 圆角三角外扩 |
| 5 | dog | 垂耳 | 耳尖下垂 |
| 6 | fox | 大尖耳 | 尖耳略长 |
| 7 | mouse | 大圆耳 | 大圆侧立 |
| 8 | pig | 小圆耳 | 极小圆贴 |
| 9 | owl | 不明显耳 | 羽状/几乎无 |
| 10 | panda | 黑边圆耳 | 圆耳+黑轮廓 |
| 11 | sheep | 卷耳 | 螺旋/卷曲形 |
| 12 | butterfly | 蝴蝶结 | 头顶蝴蝶结 |
| 13 | leaf | 叶子耳 | 叶片形 |
| 14 | star | 星形耳 | 星形装饰 |
| 15 | floppy | 大垂耳 | 大而软的垂耳 |
| 16 | none | 无耳 | 不绘制 |

---

### 3.3c 身体形状 body_form（16 种）

| # | body_form | 描述 | 基底 Shape |
|---|-----------|------|------------|
| 1 | round | 圆润 blob | Ellipse / 大圆角 |
| 2 | rounded_square | 方一点 | 小圆角矩形 |
| 3 | triangular | 水滴/三角 | 上窄下宽 Path |
| 4 | oval | 椭圆 | 水平拉长 Ellipse |
| 5 | pear | 梨形 | 上小下大圆角 |
| 6 | droplet | 水滴 | 尖顶圆底 |
| 7 | bean | 豆形 | 侧面 S 曲线 |
| 8 | cloud | 云朵 | 多弧组合 |
| 9 | star | 星形 | 五角/多角圆润 |
| 10 | heart | 心形 | 心形 Path |
| 11 | pill | 药丸形 | 胶囊/长椭圆 |
| 12 | potato | 土豆形 | 不规则圆润 |
| 13 | bell | 铃铛形 | 上小下大收口 |
| 14 | mushroom | 蘑菇形 | 圆顶+粗茎 |
| 15 | bubble | 气泡形 | 底部略平椭圆 |
| 16 | blob | 有机 blob | 不规则软边 |

---

### 3.4 物理参数（bounciness / movement_response / softness）

| personality_base | bounciness | movement_response | softness |
|------------------|------------|-------------------|----------|
| Healing | 0.3–0.4 | 0.3–0.5 | 0.7–0.9 |
| Playful | 0.6–0.8 | 0.6–0.9 | 0.5–0.7 |
| Quiet | 0.2–0.3 | 0.2–0.4 | 0.4–0.6 |
| Resilient | 0.5–0.7 | 0.5–0.7 | 0.5–0.6 |
| Warm | 0.4–0.5 | 0.4–0.6 | 0.6–0.8 |

| shell_type | 补充影响 |
|------------|----------|
| Armored | movement_response −0.1, softness −0.2 |
| Soft | softness +0.2 |
| Resilient | bounciness +0.1 |

---

### 3.5 眼细节（eye_scale / eye_spacing / blush_opacity / fuzziness）

| 人格 / 情绪 | eye_scale | eye_spacing | blush_opacity | fuzziness |
|-------------|-----------|-------------|---------------|-----------|
| openness High | 1.0–1.2 | 0.4–0.6 | 0.4–0.5 | 0.2–0.3 |
| openness Low | 0.8–1.0 | 0.5–0.7 | 0.2–0.3 | 0.1–0.2 |
| intimacy close | 1.0–1.1 | 0.5–0.6 | 0.4–0.6 | 0.15–0.25 |
| intimacy distant | 0.9–1.0 | 0.6–0.8 | 0.2–0.3 | 0.05–0.15 |
| Soft / Healing | * | * | 0.4–0.6 | 0.2–0.4 |
| Armored / Quiet | * | * | 0.1–0.2 | 0.05–0.1 |
| 默认 | 1.0 | 0.5 | 0.3 | 0.1 |

---

### 3.6 三阶段外形差异（LifeStage）

| 阶段 | 四肢 | 尾巴 | 嘴巴 | 身体比例 |
|------|------|------|------|----------|
| **newborn** | 无 | 无 | 无 | blob 0.8×0.85 |
| **child** | 短粗四肢（Chiikawa 风） | 可见 | 性格映射嘴型 | 头大身小 0.78×0.82 |
| **adult** | 略细长四肢 | 弱化 opacity 0.5 | 同 child | 头略小身略长 0.82×0.88 |

实现：ProceduralMobiView 接收 `lifeStage`，MobiLimbsView、MobiTailView、MobiMouthView 按阶段条件渲染。

---

## 4. 完整映射矩阵（速查）

| 人格组合 | material | palette | eye_shape | ear_type | body_form | bounciness | softness |
|----------|----------|---------|-----------|----------|-----------|------------|----------|
| Armored + Quiet | matte_clay | natural_clay | droopy | none/bear | rounded_square | 0.25 | 0.5 |
| Soft + Healing | fuzzy_felt | dusty_rose | gentle | rabbit | round | 0.35 | 0.85 |
| Resilient + Playful | gummy_jelly | sunshine_citrus | round | rabbit | round | 0.7 | 0.6 |
| Soft + Warm | fuzzy_felt | dusty_rose | round | bear | round | 0.45 | 0.75 |
| Resilient + Warm | smooth_plastic | dusty_rose | gentle | bear | triangular | 0.5 | 0.55 |
| Armored + * | matte_clay | deep_ocean | sharp | none | rounded_square | 0.3 | 0.4 |
| * + Quiet | (保持) | (保持) | droopy | hamster | rounded_square | −0.1 | (保持) |
| * + Tired | (保持) | (保持) | sleepy | hamster | (保持) | −0.1 | +0.1 |
| * + Defensive | matte_clay | deep_ocean | sharp | cat | rounded_square | 0.25 | 0.4 |

---

## 5. 人格槽（Personality Slot）设计

### 5.0 概念

**人格槽即灵器**：人格槽是用户画像完整度的进度概念，其**唯一**可视化为**灵器（Soul Vessel）**——胸前玻璃瓶，瓶身填充 0–100% 即人格槽进度；槽满（100%）触发进化（炸裂→胸口印记）。详见 [SoulVessel设计规范](SoulVessel设计规范.md)。

- **形态**：灵器（胸前单瓶，皮绳 + 半透明瓶身 + 熔岩灯内容物）；形状由 DNA/性格推导（circle/diamond/heart/star）。
- **位置**：挂在 Mobi 胸前。
- **填充**：数据源为画像 `slotProgress` / `completeness`；每次有意义的用户输入或画像更新驱动填充上升。
- **进化触发**：100% 满溢时触发进化事件（裂纹→炸裂→光芒融入），与 EvolutionManager 只进不退一致。

### 5.0a 槽的类型（可多选或单选实现）

| 类型 | 描述 | 填充物示例 |
|------|------|------------|
| 花纹 | 身体表面的图案 | 每格填满→纹样延伸/复杂化 |
| 挂件 | 悬挂的饰品 | 珠子、徽章、铃铛逐个出现 |
| 贴纸 | 贴纸/印花 | 每格一枚小贴纸 |
| 能量条 | 进度条式 | 条带逐段点亮 |
| 收藏格 | 格子收纳 | 每格一个「记忆碎片」图标 |

### 5.0b 填充规则（用户输入 → 槽进度）

| 输入事件 | 进度 +N |
|----------|---------|
| 每完成 1 轮对话 | +1 |
| 用户说出关键词（如情绪词、兴趣词） | +1 或 +2 |
| 特定情绪时刻（warmth 高、intimacy 升） | +1 |
| 打开日记/回忆 | +0.5（可选） |

### 5.0c 槽容量与进化

| 槽容量 | 示例值 | 满时触发 |
|--------|--------|----------|
| 默认 | 7 或 10 格 | 进化到下一阶段（如 colorShift 解锁） |
| 可配置 | 与 EvolutionManager 现有阈值联动 | recordRoomInteraction / keyword 累积 |

### 5.0d 视觉实现（SwiftUI）

- **灵器（SoulVesselView）**：根据 `slotProgress`（0.0–1.0）驱动瓶身填充；长按展示 Soul Sync Rate。与 EvolutionManager.personalitySlotProgress 联动。
- 历史/备选：7 格配件形态（PersonalitySlotView）已不再在身体上展示，仅灵器作为人格槽可视化。

---

## 6. 实施要点（方案 B）

### 6.1 SwiftUI 眼型扩展（16 种）

- 在 `ProceduralMobiView` 的 `EyeView` 中支持 16 种 eye_shape。
- 每种对应独立 Shape 或 Path 实现。
- `MobiVisualDNA.eyeShape` 支持 3.3 节全部枚举。

### 6.2 SwiftUI 耳朵扩展（16 种）

- `MobiVisualDNA` 新增 `earType: String`。
- `EarOverlayView(earType:)`：根据 earType 绘制 16 种形态，贴于头顶。
- 与 body 同色/同 palette。

### 6.3 SwiftUI 身体形状扩展（16 种）

- `MobiVisualDNA` 新增 `bodyForm: String`。
- `MobiBodyMaterialView` 根据 `bodyForm` 切换 16 种基底 Shape。
- 复用/扩展 `bodyShapeFactor` 做细微变形。

### 6.4 人格槽（灵器）实现

- 槽进度由 `EvolutionManager.personalitySlotProgress`（画像 slotProgress）提供。
- 灵器（SoulVesselView）渲染在 Mobi 胸前，瓶身填充 = 人格槽进度。
- 100% 满溢时触发满溢动画并调用 `EvolutionManager.markVesselOverflowed()`，与进化只进不退一致。

### 6.5 映射执行位置

| 场景 | 执行位置 |
|------|----------|
| 强模型返回完整 DNA | StrongModelSoulService → 直接使用，可选后处理校正 |
| Fallback（无 transcript） | GeminiVisualDNAService → Prompt 中补充 eye_shape sharp/gentle/sleepy |
| 前端兜底 | `PersonalityToDNAMapper`（新建）根据 SoulProfile 推导 DNA，供 API 失败时使用 |

### 6.6 需修改文件

| 文件 | 变更 |
|------|------|
| MobiVisualDNA.swift | 新增 earType、bodyForm；eye_shape 支持 16 种 |
| ProceduralMobiView.swift | EyeView 16 种；EarOverlayView 16 种；bodyForm 16 种；灵器（SoulVesselView）为人格槽唯一展示 |
| EvolutionManager.swift | 人格槽进度管理，或新建 PersonalitySlotManager |
| GeminiVisualDNAService.swift | Prompt 补充 16 种 eye/ear/body 及映射 |
| StrongModelSoulService.swift | 响应 schema 支持 ear_type、body_form、16 种枚举 |

---

## 6b. 与 MVP-Phase-Plan 对应

| MVP 需求 | 本表 |
|----------|------|
| MBTI 眼型 | 16 种 eye_shape 由 personality 映射 |
| Soul Vessel | 见 [SoulVessel设计规范](SoulVessel设计规范.md)；胸前玻璃挂坠，画像完整度可视化；与人格槽并存 |
| MobiVisualDNA 材质 | material_id 映射表 3.1 |
| 进化 Slots | colorShift / coffeeCup 由 EvolutionManager 管理 |
| **人格槽** | 新增长在 Mobi 身上的配件槽，用户输入填充，槽满触发进化 |

---

## 7. 资产清单汇总（对应 UI 图）

| 资产 | 说明 |
|------|------|
| eye_shape | 眼型 **16 种**：round / droopy / line / sharp / gentle / sleepy / dot / star / heart / diamond / crescent / wide / narrow / upturned / curious / sparkle |
| ear_type | 耳朵 **16 种**：rabbit / hamster / bear / cat / dog / fox / mouse / pig / owl / panda / sheep / butterfly / leaf / star / floppy / none |
| body_form | 形状 **16 种**：round / rounded_square / triangular / oval / pear / droplet / bean / cloud / star / heart / pill / potato / bell / mushroom / bubble / blob |
| **personality_slot** | **人格槽**：花纹/挂件/贴纸，用户输入填满 → 进化触发 |
| material_id | 材质 |
| palette_id | 配色 |
| bounciness / movement_response | 弹性 / 响应 |
| blush_opacity / fuzziness | 腮红 / 毛茸 |
| eye_scale / eye_spacing | 眼大小 / 眼间距 |

人格 → 上述资产排列组合 → 唯一 Mobi 实例。人格槽随互动填充 → 槽满进化。**Soul Vessel**（胸前玻璃挂坠，画像完整度可视化）见 [SoulVessel设计规范](SoulVessel设计规范.md)，与人格槽并存。

---

*文档版本：2025-02，方案 B 纯 SwiftUI，16 种眼/耳/形 + 人格槽*
