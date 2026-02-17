# Soul Vessel（灵器）施工顺序表

**说明：** 设计规范见 [SoulVessel设计规范](SoulVessel设计规范.md)。本表为灵器相关实现与对接的推荐施工顺序，与主 [施工顺序表](施工顺序表.md) 并行或在其后执行。

---

## 顺序表（可逐项勾对）

| 序号 | 项 | 谁做 | 说明 / 产出 |
|-----:|---|------|-------------|
| 0 | **设计规范与文档同步** | 当前助手 | 已完成。见 [SoulVessel设计规范](SoulVessel设计规范.md)；MVP-Phase-Plan、PhaseIII、施工顺序表、用户画像、画像契约、Mobi完整指南、Mobi交互行为完整设计、mvp-plan-workflow 已引用或扩展。 |
| 1 | **数据与契约** | 当前助手 | 已完成。**MVP 决策**：用现有 slotProgress/completeness 驱动 Vessel；vessel_fill/vessel_shape_type 为可选扩展。客户端推导规则见 [SoulVessel设计规范](SoulVessel设计规范.md) §5；画像-进化接口契约、画像服务设计已补充。 |
| 2 | **Soul Vessel 视觉资产** | 资产 Agent | 已完成。皮绳 + 半透明玻璃瓶（蜡笔描边）；熔岩灯内容物；形状由 materialId 推导；SoulVesselView、ProceduralMobiView 集成。 |
| 3 | **填充与光效** | 资产 Agent | 已完成。slotProgress 驱动 0–100% 填充；personalitySlotProgress 增加时 vesselAgitated 触发光点飞入、液面激荡。MobiAssetViews。 |
| 4 | **点击与长按交互** | 资产 Agent | 已完成。点击触觉+音效；长按弹层 Soul Sync Rate %；vessel_tap/vessel_long_press 上报。RoomContainerView、SoulSyncSheetView。 |
| 5 | **100% 满溢与进化衔接** | 进化 Agent | ✅ 已完成。slotProgress≥1 时触发：裂纹(0.6s)→炸裂(0.5s)→光芒融入(0.7s)→胸口印记；EvolutionManager.vesselHasOverflowed 持久化、只进不退；Mobi 永久变化依赖既有 colorShift 等。见 EvolutionManager.markVesselOverflowed、SoulVesselView.overflowPhase、SoulVesselChestMarkView。 |
| 6 | ~~懂你金句~~ | 已落实 | 已取消，无需开发。长按 Vessel 仅展示 Soul Sync Rate（序号 4 已实现）；代码与文档已无金句逻辑。 |
| 7 | **Fact 粒度注入（可选）** | 当前助手 / 画像服务 | 已完成。设计见 [Fact粒度注入设计](Fact粒度注入设计.md)：Fact 类型与填充量、数据流、与画像/EverMemOS 对接、提取方式（规则/LLM）、API 扩展；实现优先级 P0 无需、P1 用 completeness、P2 接入 Fact 提取。 |

---

## 依赖关系简图

```
0 文档同步 → 1 数据契约
     ↓
2 视觉资产 → 3 填充与光效
     ↓
4 点击/长按交互
     ↓
5 满溢进化衔接
     ↓
7 Fact 粒度（可选，后端扩展）
```

---

## 与主施工顺序表的关系

- 主表 **序号 11（Mobi 资产生成部分）**；本表 Soul Vessel 序号 2–5 已实现。角色图/视频由独立项目「Mobi资产生成」管线生成，本仓消费；金句已取消。
- 项目经理 Agent 可按本表拆任务与排期；资产 Agent 主责 2–4，进化 Agent 主责 5；金句已取消。

---

## 相关文档

| 文档 | 路径 |
|------|------|
| Soul Vessel 设计规范 | docs/SoulVessel设计规范.md |
| Fact 粒度注入设计 | docs/Fact粒度注入设计.md |
| 施工顺序表（总表） | docs/施工顺序表.md |
| 画像-进化接口契约 | docs/画像-进化接口契约.md |
| Phase III 资产与人格映射表 | docs/PhaseIII-资产与人格映射表.md |
