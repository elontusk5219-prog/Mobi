# Mobi 行为模块实现说明

**文档用途：** 记录 Mobi 行为模块（施工顺序表 item 5）的实现细节。置信度衰减表现、seeking 按成长阶段差异化；**阶段话术**：newborn 乱码语学说话（铭印<3）/ 简单中文，child 小孩话，adult 正常伙伴。

**维护：** 2025-02 创建。设计见 [Mobi交互行为完整设计](Mobi交互行为完整设计.md)、[画像-进化接口契约](画像-进化接口契约.md)。

---

## 1. 实现范围

| 项 | 说明 | 状态 |
|-----|------|------|
| 置信度衰减时的表现 | roomSystemPrompt 注入「拿不准你」话术；seeking 时「好久没见」类指令 | 已实现 |
| seeking 按阶段差异化 | newborn（铭印<3 乱码语 / 否则简单问候）、child 小孩式好奇、adult 关心类 | 已实现 |
| 阶段话术（roomSystemPrompt） | newborn 乱码语学说话（useNewbornGibberish）或简单本能；child 小孩话；adult 伙伴话 | 已实现 |

---

## 2. 文件变更

| 文件 | 变更 |
|------|------|
| [MobiPrompts.swift](Mobi/Core/MobiPrompts.swift) | `roomSystemPrompt(..., stage:, useNewbornGibberish:)` 按阶段注入话术（newborn 乱码/本能、child 小孩话、adult 伙伴）；`seekingInstruction(stage:confidenceDecay:useNewbornGibberish:)` |
| [DoubaoRealtimeService.swift](Mobi/Services/Network/Doubao/DoubaoRealtimeService.swift) | `prepareForRoom(..., stage:, useNewbornGibberish:)` 传入 stage 与 newborn 乱码语开关（铭印<3 时为 true） |
| [RoomContainerView.swift](Mobi/Features/Room/Views/RoomContainerView.swift) | `prepareForRoom` 传入 `evolution.confidenceDecay`、`evolution.effectiveStage`、`useNewbornGibberish = (effectiveStage==.newborn && 铭印数<3)`；seeking 时调用 `MobiPrompts.seekingInstruction(stage:..., useNewbornGibberish:)` |

---

## 3. 置信度衰减

**数据来源**：EvolutionManager.confidenceDecay（来自画像 API EvolutionProfileResponse.confidenceDecay）

**表现**：

1. **roomSystemPrompt**：当 `confidenceDecay == true` 时，在 Rules 后追加：
   ```
   # Confidence Decay
   You sense the user has been away. You feel a bit uncertain, slightly distant. You may say things like "好久没见" or "你好像有点不一样". Stay gentle but a little tentative.
   ```

2. **seeking**：当 `confidenceDecay == true` 时，忽略阶段，统一发送：
   ```
   The user has been away. Say something like "好久没见" or "你好像有点不一样" — warm but a little tentative, as if you're not quite sure of them anymore.
   ```

**阶段不退**：置信度衰减不改变 evolution 阶段；仅影响话术与行为。

---

## 4. seeking 指令映射

| effectiveStage | confidenceDecay | useNewbornGibberish（仅 newborn） | 指令 |
|----------------|-----------------|-----------------------------------|------|
| * | true | — | 好久没见类（见上） |
| genesis | false | — | 极短问候「嗯?」「Hey.」（Room 内通常不出现 genesis） |
| newborn | false | true（铭印数 < 3） | 乱码语「Ba boo? Mm hmm nyeh?」 |
| newborn | false | false | 极短问候「嗯?」「Hey.」 |
| child | false | — | 小孩式好奇「你在干嘛呀？」 |
| adult | false | — | 关心类「你最近还好吗？」 |

---

## 5. 数据流

```
EvolutionProfileService.fetch()
    → EvolutionManager.applyProfileResponse()
    → confidenceDecay, effectiveStage 更新

Room onAppear:
    evolution.fetchAndApplyProfile()
    prepareForRoom(..., stage: evolution.effectiveStage, confidenceDecay: evolution.confidenceDecay, useNewbornGibberish: effectiveStage==.newborn && 铭印数<3)

Room tick (seeking 触发):
    MobiPrompts.seekingInstruction(stage: evolution.effectiveStage, confidenceDecay: evolution.confidenceDecay, useNewbornGibberish: ...)
    → DoubaoRealtimeService.sendTextInstruction(...)
```

---

## 6. 相关文档

| 文档 | 路径 |
|------|------|
| Mobi 交互行为完整设计 | docs/Mobi交互行为完整设计.md |
| 画像-进化接口契约 | docs/画像-进化接口契约.md |
| Mobi 用户画像与进化驱动设计 | docs/Mobi用户画像与进化驱动设计.md |
| 施工顺序表 | docs/施工顺序表.md |

---

*文档版本：2025-02，初版。*
