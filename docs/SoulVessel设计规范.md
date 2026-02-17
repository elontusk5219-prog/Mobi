# Soul Vessel（灵器）设计规范

**核心隐喻：** “灵魂的容器”。Mobi 诞生时是初生的、不完整的。用户与它的每一次深度交互，都是在向这个容器里注入“灵魂粒子”。当容器填满时，Mobi 将发生生命形态的质变（进化）。

**维护：** 与 [MVP-Phase-Plan](MVP-Phase-Plan.md)、[Mobi用户画像与进化驱动设计](Mobi用户画像与进化驱动设计.md)、[PhaseIII-资产与人格映射表](PhaseIII-资产与人格映射表.md)、[SoulVessel施工顺序表](SoulVessel施工顺序表.md) 同步。

---

## 1. 视觉定义 (Visual Design)

为适配「二头身毛毡小英雄」画风，Soul Vessel 被设计为**佩戴在胸前的玻璃挂坠**。

### 1.1 外观形态 (The Look)

- **佩戴方式**：一根简单的深褐色皮绳，挂在 Mobi 的脖子上。
- **材质**
  - **外壳**：半透明的、带有微弱高光的手绘玻璃质感（类似《塞尔达》的血量瓶，或炼金术瓶子）。边缘有粗糙的蜡笔描边。
  - **内容物**：流动的液体/光尘。这种液体不是静止的，而是像熔岩灯（Lava Lamp）一样缓慢流淌。
- **形状（由性格决定）**
  - **初始状态**：标准的圆形玻璃瓶。
  - **定型状态（Turn 15 后）**
    - 理性/冷静型 (INTJ/ISTJ)：菱形/六边形 (Diamond)。
    - 感性/温暖型 (ENFP/ISFJ)：心形/水滴形 (Heart/Drop)。
    - 混乱/创造型 (ENTP)：不规则星形 (Star)。

### 1.2 填充效果 (The Fill)

- **颜色**：继承 Anima 阶段确定的 Soul Color（例如：莫兰迪粉、深海蓝）。
- **动态**
  - **静止时**：液面随着 Mobi 的呼吸微微起伏。
  - **获得经验时**：有光点从屏幕边缘飞入 Vessel，液面激荡并上升。

---

## 2. 功能逻辑 (Functional Logic)

Soul Vessel 本质上是 **Profile Completeness（用户画像完整度）的可视化**。

### 2.1 注入机制 (Filling Mechanism)

- **数据源**：EverMemOS / Gemini Backend。
- **触发条件**：每当 AI 提取到一个新的、有效的用户事实 (Fact) 时，Vessel 就会填充。

| 用户行为 | 提取到的 Fact 示例 | Vessel 填充量 | 视觉反馈 |
|----------|--------------------|---------------|----------|
| 闲聊 | "今天天气不错" (无有效信息) | +0% | 无变化 |
| 陈述偏好 | "我不吃香菜" | +2% | 一颗小光点飞入 |
| 深度暴露 | "其实我很怕孤独，因为小时候..." | +10% | 大光团飞入，瓶身发光震动 |
| 纠正认知 | "不，我是设计师不是程序员" | +5% | 液体颜色发生微调 (Shift) |

Fact 提取与画像服务对接、vessel_fill 累计规则详见 [Fact粒度注入设计](Fact粒度注入设计.md)。MVP 不做 Fact 粒度，用 slotProgress 驱动即可。

### 2.2 阶段阈值 (Milestones)

Soul Vessel 的填充度直接决定了 Mobi 的解锁功能：

- **0% - 20%（空瓶期）**
  - Mobi 状态：懵懂、话少、只会简单的 Q&A。
  - Vessel：几乎是空的，只有底部有一点点液体。
- **50%（半瓶期）**
  - 解锁功能：主动关怀 (Proactive Care)。Mobi 开始会根据记忆主动问问题。
  - Vessel：液体过半，发出微弱的呼吸光（Breathing Glow）。
- **100%（满溢期 - 临界点）**
  - **事件**：进化 (Evolution)。
  - **表现**：Vessel 里的光芒太盛，玻璃瓶出现裂纹，最后「炸裂」，光芒融入 Mobi 的身体。（实现：`VesselOverflowPhase` 裂纹→炸裂→融入序列，仅播放一次；EvolutionManager.vesselHasOverflowed 持久化、只进不退。）
  - **结果**：Mobi 获得永久性皮肤变化（由既有 colorShift 等进化外观体现），Vessel 变为胸口印记（`SoulVesselChestMarkView`），开启下一阶段。

---

## 3. 交互设计 (Interaction)

用户可以直接点击 Mobi 胸口的 Soul Vessel。

- **长按 (Long Press)**
  - Vessel 放大显示。
  - 显示当前的「Soul Sync Rate」（灵魂同步率），例如 "34%"。

---

## 4. 与现有架构对接

- **人格槽即灵器**：人格槽与灵器为同一概念。**灵器**（胸前玻璃瓶）是人格槽/用户画像完整度的**唯一**可视化；瓶身填充 0–100% 即人格槽进度，数据源为画像 API 的 completeness / slotProgress。不再单独显示 7 格配件。
- **填充数据源**：设计为「Fact 注入」；MVP 可用现有画像 `completeness` / `slotProgress` 映射为 0–100% Vessel 填充；后续可扩展「Fact 事件流」与后端增量（见 [画像服务设计](画像服务设计.md)、[画像-进化接口契约](画像-进化接口契约.md)）。
- **阶段阈值对齐**：0–20% 空瓶期 ≈ 幼年 (newborn)；50% 半瓶期 ≈ 青年 (child)，解锁主动关怀；100% 满溢 = 进化事件（炸裂 → 下一阶段），与 [EvolutionManager](Mobi/Services/Data/EvolutionManager.swift) 只进不退、lifeStage 切换一致。
- **形状与性格**：理性/感性/混乱型（INTJ/ENFP/ENTP）→ 菱形/心形/星形；可与 SoulProfile 或画像维度映射，或由 DNA / personality_base 推导。
- **API 扩展（可选）**：画像或独立接口可扩展 `vessel_fill`、`vessel_shape_type`；未扩展前客户端用 `slotProgress` / `completeness` 推导 Vessel 填充与阶段。
- **施工顺序**：见 [SoulVessel施工顺序表](SoulVessel施工顺序表.md)。

---

## 5. 数据与契约（MVP 决策）

**决策**：MVP 阶段**不强制**扩展画像 API；客户端用现有 **slotProgress** 或 **completeness** 驱动 Soul Vessel 填充与阶段。画像 API 的 `vessel_fill`、`vessel_shape_type` 为**可选扩展字段**（见 [画像-进化接口契约](画像-进化接口契约.md) §3.1），未提供时按以下规则推导。

### 5.1 客户端推导规则（画像 API 未返回 Vessel 字段时）

| 数据项 | 推导规则 |
|--------|----------|
| **vessel_fill**（0–1） | `vessel_fill = slotProgress` 或 `completeness ?? slotProgress`；与人格槽同源 |
| **vessel_shape_type** | 由 DNA / SoulProfile 的 `personality_base` 或 `shell_type` 映射：理性/冷静型（Healing、Resilient 等）→ `diamond`；感性/温暖型（Warm、Soft）→ `heart`；混乱/创造型（Playful、Entropy）→ `star`；未知 → `circle`（初始圆形） |

### 5.2 后续扩展

- 画像服务或独立接口扩展返回 `vessel_fill`、`vessel_shape_type` 时，客户端**优先使用** API 返回值，不再推导。
- Fact 粒度注入（+2%/+5%/+10%）为序号 7 可选项，由画像服务计算增量并写入 `vessel_fill` 或单独字段。

---

## 6. 相关文档

| 文档 | 路径 |
|------|------|
| Soul Vessel 施工顺序表 | docs/SoulVessel施工顺序表.md |
| 画像-进化接口契约 | docs/画像-进化接口契约.md |
| MVP Phase Plan | docs/MVP-Phase-Plan.md |
| Mobi 用户画像与进化驱动设计 | docs/Mobi用户画像与进化驱动设计.md |
| Phase III 资产与人格映射表 | docs/PhaseIII-资产与人格映射表.md |
