# MVP 待办清单 · 分工表

**用途：** 项目经理分工用。进度与 [MVP-Phase-Plan §7](MVP-Phase-Plan.md#7-待办与缺口)、[Mobi用户画像与进化驱动设计 §9](Mobi用户画像与进化驱动设计.md#9-待办与实现要点) 对齐，有变更需同步更新两处。

**目标日期：** Feb 17, 2026 (CNY Launch)

---

## 使用说明

- **优先级**：P0 必上 MVP，P1 画像闭环，P2 体验增强，P3 可后置或依赖后端。
- **负责人**：由项目经理填写；**验收** 一列可作为 DoD 参考。
- 完成后在 MVP-Phase-Plan §7 或本表对应行注明「已实现」并更新日期。

---

## P0：必上 MVP（体验/一致性）

| 序号 | 模块 | 任务项 | 说明 / 验收 | 负责人 |
|------|------|--------|-------------|--------|
| P0-1 | Anima / 记忆 | Anima 遗忘 | 确保 birthMemories 不表述为「Mobi 记得 Anima 对话」；persona 仅含性格描述，不含对话内容引用。验收：Room 内无「你之前在 Anima 说过」类话术来源。**已实现**：birthMemories 仅存不注入；MemoryDiaryService 已加 Anima 遗忘注释；StrongModelSoulService persona 指令已加固；persona 仅性格描述。 | Anima 对话逻辑（主责）+ Mobi 记忆模块 |
| P0-2 | Room / 视觉 | newborn / child / adult 视觉差异 | 三阶段在至少 1～2 个视觉维度可区分（如体型、颜色、显隐、动画节奏）。验收：Debug 切阶段或自然进化后用户能明显看出当前阶段。涉及：ProceduralMobiView、EvolutionManager.effectiveStage、可选 MobiAssetViews。**已实现**：体型 newborn 0.72×0.76 scale 0.88 / child 0.78×0.82 / adult 0.85×0.9；动画节奏 child 活泼（呼吸 1.15×）、adult 沉稳（0.9×）；颜色饱和 newborn 0.88 / adult 1.08；四肢/尾巴/嘴仅 child+。 | Mobi 视觉资产管理 |

---

## P1：画像与进化闭环（上游/后端 + 对接）

| 序号 | 模块 | 任务项 | 说明 / 验收 | 负责人 |
|------|------|--------|-------------|--------|
| P1-1 | 后端 / 画像 | 画像服务架构 | 以 EverMemOS 为底座的画像上游服务；人格维度定义（参照 Big Five/HEXACO）与置信度计算；METADATA 沉淀为 SoulProfile，SoulProfile 作为画像 Anima 部分。验收：服务可输出各维度估计值 + 置信度。 | 项目经理（后端） |
| P1-2 | 后端 / 画像 | 完整度聚合与阈值 | 阈值 A（幼年→青年）、B（青年→成年）的取值与更新策略。验收：客户端或服务端可依完整度判定阶段。**已实现**：设计文档 §4.1a 定 A=0.5、B=0.8 与更新策略；客户端在未返回有效 lifeStage 时用 completeness 推导阶段并写入缓存（EvolutionProfileResponse.derivedLifeStageFromCompleteness + EvolutionManager.applyProfileResponse）。 | Mobi 进化机制 |
| P1-3 | 后端 / 行为 | 行为上报或推断 | Room 内行为（戳击、长按、沉默等）进入 EverMemOS 或画像输入；格式与通道见《行为上报与画像输入》。验收：行为数据可被画像侧消费。 | Mobi 行为模块 |
| P1-4 | 后端 / 客户端 | 人格槽 API | 客户端获取「当前完整度/各维度置信度」的接口或缓存策略。验收：EvolutionManager 或等价处可读画像驱动结果。**客户端已实现**：EvolutionProfileService + EvolutionManager 已对接画像/Mock，可读 slotProgress、lifeStage、completeness 等。 | 项目经理（后端）+ Mobi 进化机制（客户端） |
| P1-5 | 客户端 / 进化 | 与 EvolutionManager 对接 | 人格槽与进化解锁改为读取画像驱动结果；保留只进不退与状态持久化。验收：有画像 API 时用画像，无时保留现有 Mock/降级。**已实现**：人格槽与进化解锁读画像；只进不退与持久化已接；有/无画像时 Mock/降级见进化机制实现说明。 | Mobi 进化机制 |

---

## P2：体验增强

| 序号 | 模块 | 任务项 | 说明 / 验收 | 负责人 |
|------|------|--------|-------------|--------|
| P2-1 | Room / 视觉 | lookDirection 由 attention 驱动 | 眼睛/视线由「用户方向、拖拽、沉默漂移」等 attention 目标驱动，而非仅拖拽。验收：用户说话时 Mobi 朝用户，沉默时微漂移等符合设计。**已实现**（MobiBrain + Room tick lookTarget 优先级 + lerp）。 | Mobi 大脑模块 |
| P2-2 | 后端 / 客户端 | 置信度衰减与行为 | 衰减信号下发给客户端或通过 memoryContext/persona 注入，驱动「拿不准你」类话术与行为。验收：长期未互动后 Mobi 话术/行为有可感知的谨慎/疏离。 | Mobi 行为模块 |
| P2-3 | 后端 / 画像 | Mobi 模仿用户语言习惯 | 从用户对话提取用词、句式、语气；产出描述或示例注入 roomSystemPrompt；按阶段调节模仿强度。验收：Room 对话可选用用户习惯的表述方式（与画像数据源衔接）。**对话侧已实现**：roomSystemPrompt 已支持 languageHabits 参数注入端（MobiPrompts、prepareForRoom）；提取与数据源由画像侧/序号10负责。 | Mobi 对话模块 |
| P2-4 | Room / 叙事 | child / adult 跨会话记忆与身份叙事 | 青年/成年阶段可引用「你上次说过…」、身份叙事、主动关怀。验收：记忆注入与 stage 话术已接好；叙事深度可迭代。**已实现**：记忆模块 fetchMemoriesForSession(stage) 各阶段均注入 memoryContext（newborn 条数少、child/adult 更多）；roomSystemPrompt 按 stage 注入话术，newborn 话术简短本能，adult 阶段显式支持「你上次说过…」「我们之前聊过…」。 | Mobi 记忆模块（主责）+ Mobi 对话模块 |

---

## P3：可后置或依赖后端

| 序号 | 模块 | 任务项 | 说明 / 验收 | 负责人 |
|------|------|--------|-------------|--------|
| P3-1 | Phase I 音频 | Turn 13 渐入 Video Audio | Turn 11+ ping + 主 ambient 音量随 turn 微降（reverb 递减），与视频渐入衔接。验收：听感上过渡自然。**已实现**：AmbientSoundService 已做 latePhaseVolumeScale（turn 11→15 约 1.0→0.8×）。 | 项目经理 |
| P3-2 | 后端 | Voice ID | 依赖后端能力，当前未实现。验收：按产品需求对接。 | 项目经理（后端） |
| P3-3 | 后端 / 客户端 | 日记 API 全量对接 | fetchYesterdaySummary 等与真实后端对接（若尚未完全对接）。验收：日记能力符合契约。**已实现**：fetchYesterdaySummary 已对接 EverMemOS search（时间范围检索，无结果回退 mock）。 | Mobi 记忆模块 |
| P3-4 | Room / 大脑 | 状态觉察注入（可选） | MobiBrain 状态 → LLM prompt / sendTextInstruction。验收：按设计文档决定是否上 MVP。**已实现**：MobiBrain.stateContextForPrompt 产出 derivedState/arousal/attention 描述；seeking 时 sendTextInstruction 注入 [Context: You are in a seeking state. Arousal: medium. Attention: focused.] 前缀。 | Mobi 大脑模块 |

---

## 审核结果（代码与契约核对）

**审核日期：** 2026-02（按分工表验收标准逐项核对代码与文档。）

| 序号 | 结论 | 依据 |
|------|------|------|
| **P0-1** | ✅ 通过 | `getBirthMemories()` 未在 Room 流程中调用；Room 的 memoryContext 仅来自 `EverMemOSMemoryService.fetchMemoriesForSession`。StrongModelSoulService  persona 指令明确禁止 "Mobi remembers / 你 said in Anima"。MemoryDiaryService 注释写明 birthMemories 仅存不注入。 |
| **P0-2** | ✅ 通过 | ProceduralMobiView 按 `lifeStage` 分支：体型 bodyRatio（newborn 0.72×0.76 / child 0.78×0.82 / adult 0.85×0.9）、stageScale（newborn 0.88）、stageSaturation（newborn 0.88 / adult 1.08）、呼吸节奏（child 1.15× / adult 0.9×）、MobiLimbsView/MobiTailView 仅 child+；MobiAssetViews 亦有 lifeStage 分支。RoomContainerView 传入 `evolution.effectiveStage`。 |
| **P1-1** | ⏳ 待后端确认 | 客户端已预留 EvolutionProfileService（baseURL + API Key）；画像服务架构与维度定义属后端实现，本仓无法核对。 |
| **P1-2** | ✅ 通过 | `EvolutionProfileResponse.derivedLifeStageFromCompleteness(thresholdA: 0.5, thresholdB: 0.8)`；`applyProfileResponse` 在 lifeStage 为空时用 completeness 推导并写入缓存。 |
| **P1-3** | ✅ 通过 | BehaviorReportingService 将 poke/drag/longPress/silenceInterval 等写入 EverMemOS（sender=mobi_behavior），契约见《行为上报与画像输入》。 |
| **P1-4** | ✅ 客户端通过 | EvolutionProfileService.fetch() 调画像 API 或 Mock；EvolutionManager 通过 applyProfileResponse 写入 cachedProfile，personalitySlotProgress / effectiveStage 等均来自缓存。后端需部署并配置 PROFILE_EVOLUTION_BASE_URL。 |
| **P1-5** | ✅ 通过 | fetchAndApplyProfile → applyProfileResponse；只进不退（order >= currentOrder）；持久化 persistCachedProfile；无画像时 Mock 见 EvolutionProfileService.mockResponse()。 |
| **P2-1** | ✅ 通过 | Room tick 中 target：listening 且 power>0.1 → userDirection；拖拽 → 跟手；seeking → 随机；否则 0.95 衰减。lookDirection lerp 平滑。 |
| **P2-2** | ✅ 客户端通过 | confidenceDecay 从 cachedProfile 读取并传入 prepareForRoom、roomSystemPrompt、seekingInstruction；话术块已存在。需画像 API 返回 confidenceDecay 才生效。 |
| **P2-3** | ✅ 注入端通过 | roomSystemPrompt(languageHabits:)、prepareForRoom(languageHabits: evolution.languageHabits)；EvolutionProfileResponse.languageHabits、cachedProfile 持久化。提取与数据源属画像侧。 |
| **P2-4** | ✅ 通过 | fetchMemoriesForSession(stage) newborn 返回 ""，child/adult 检索；stageGuidanceBlock(adult) 含「你上次说过…」「我们之前聊过…」；memoryContext 注入 # Memory。 |
| **P3-1** | ✅ 通过（拍板） | Turn 11+ 已有 2–4 kHz 周期 ping；**拍板**：reverb 递减以「主 ambient 音量随 turn 11→15 微降」实现（AmbientSoundService.latePhaseVolumeScale，turn 15 约 0.8×），听感贴近渐入视频。 |
| **P3-2** | ❌ 未实现（拍板） | **拍板**：依赖后端，客户端不实现；对接时机与接口约定见全栈白皮书 / 产品需求。 |
| **P3-3** | ✅ 通过（拍板） | **拍板**：客户端已实现 fetchYesterdaySummary（EverMemOS search + startTime/endTime）；后端支持时间范围检索即视为全量对接，契约见日记API契约.md。 |
| **P3-4** | ✅ 通过 | RoomContainerView 调用 seekingInstruction(..., brainStateContext: brain.stateContextForPrompt)；MobiPrompts 已支持 brainStateContext 注入。 |

**汇总（拍板后）：** P0/P1 客户端与 P2/P3（除 P3-2 Voice ID）均已落地或拍板通过；P1-1 画像服务架构待后端；P3-2 为后端能力，客户端不做实现。

---

## 建议施工顺序

按依赖关系与可并行度划分批次，同一批内可并行；有箭头表示「建议先后」。

| 批次 | 任务 | 说明 |
|------|------|------|
| **第一批** | P0-1、P0-2 | **可并行**。无前置依赖，先做可尽早稳住 MVP 体验与一致性。 |
| **第二批** | P1-1 → P1-2 | 先有画像服务架构与维度/置信度（P1-1），再定完整度聚合与阈值 A/B（P1-2）。P1-3 行为上报可与 P1-1 并行（约定格式与通道，供画像消费）。 |
| **第三批** | P1-4 → P1-5 | 人格槽 API（P1-4）依赖画像侧有接口或约定；EvolutionManager 对接（P1-5）依赖 P1-4 或 Mock。 |
| **第四批** | P2-1、P2-2、P2-3、P2-4 | P2 可在 P1 闭环基本就绪后并行推进：P2-1 仅客户端；P2-2 依赖画像下发衰减；P2-3/P2-4 与记忆/对话管道衔接。 |
| **第五批** | P3-1～P3-4 | 按档期与后端能力排期；Voice ID、日记 API 等依赖后端。 |

**简要顺序链：**  
P0（并行）→ P1-1 + P1-3（并行）→ P1-2 → P1-4 → P1-5 → P2（多线并行）→ P3（按需）。

---

## 已实现（无需分工，仅作对照）

以下在 MVP-Phase-Plan / 用户画像 §9 中已标为已实现，本表不分配：

- 双脑架构（Actor + Director）、Anima 15 轮弧、Cosmic Sneeze、Phase II 音效（10s Boom / 25s BER）
- Room：出生配置、Parallax、昼夜、Mobi Drop、DNA/材质、16 种眼/耳/身型、人格槽（灵器）、Soul Vessel 视觉+交互+满溢、Doubao 人设注入、MobiBrain、记忆日记对接
- 进化与行为：EvolutionManager 客户端机制、只进不退、Mock/降级、置信度衰减话术、seeking 按阶段差异化、Room 对话按 stage 与 languageHabits 注入
- 日记：EverMemOS search 对接

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-02 | 初版：从 MVP-Phase-Plan §7 与用户画像 §9 整理，拆 P0～P3，留负责人列供分工。 |
| 2026-02 | 按 Pin 模块填写负责人：项目经理、Mobi 视觉资产管理、Mobi 进化机制、Mobi 对话/记忆/行为/大脑模块、Anima 对话逻辑。 |
| 2026-02 | 新增「建议施工顺序」：五批次，P0 并行 → P1 画像底座 → P1 对接 → P2 并行 → P3 按需。 |
| 2026-02 | 新增「审核结果」：按验收标准逐项核对代码与契约；P0/P1 客户端/P2 通过，P1-1 与 P3 部分待后端或再确认。 |
| 2026-02 | 对话模块验收：P0-1 Anima 遗忘已满足（birthMemories 不注入、persona 仅性格描述）；P2-3 对话侧 languageHabits 注入端已实现；P2-4 对话侧 stage 话术与记忆注入已接好。本表对应行已注明。 |
| 2026-02 | 记忆模块验收：P0-1 记忆侧 MemoryDiaryService 已加 Anima 遗忘注释；P2-4 记忆注入与 stage 检索、BehaviorReportingService 已实现；P3-3 日记 EverMemOS 对接已实现。 |
| 2026-02 | **拍板与落地**：按 agent-teams-playbook 执行；task_plan 拍板 P1-1/P3-1/P3-2/P3-3；P3-1 实现 latePhaseVolumeScale（Turn 11–15 ambient 微降）；审核结果与分工表更新为拍板后结论。 |
