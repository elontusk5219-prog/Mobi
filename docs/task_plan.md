# Task Plan · MVP 拍板与落地

**执行方式：** agent-teams-playbook 6 阶段（规划 → Skill 发现 → 分工 → 执行 → 质量 → 交付）

---

## Phase 0：规划与拍板结论

| 项 | 拍板结论 |
|----|----------|
| **P1-1 画像服务架构** | 后端实现；客户端已预留 EvolutionProfileService(baseURL + API Key)。契约见 docs/画像-进化接口契约.md。不阻塞 MVP 发布。 |
| **P3-1 Turn 13 渐入 Video Audio** | ping 已实现（Turn 11+ 2–4 kHz 周期 ping）；「reverb 递减」在无独立 reverb 单元下以 **ambient 音量随 turn 11→15 微降** 实现，听感上氛围略收、更贴近视频切入。 |
| **P3-2 Voice ID** | 依赖后端；客户端不实现。在契约/白皮书中注明对接时机与接口约定即可。 |
| **P3-3 日记 API** | 客户端已实现 fetchYesterdaySummary（EverMemOS search + startTime/endTime）；后端支持时间范围检索即视为全量对接。契约见日记API契约.md。 |

---

## Phase 1：缺口清单（本次执行）

1. **P3-1**：AmbientSoundService 在 Turn 11–15 对主 ambient 做轻微音量 taper（e.g. turn 15 时 0.15 → 0.12），实现「渐入视频」的听感。
2. **文档**：MVP待办清单-分工表 审核结果中 P3-1/P3-2/P3-3 更新为拍板后结论；P1-1 注明「待后端」。
3. **质量**：确认无遗漏——birthMemories 不注入 Room、三阶段视觉、画像对接、行为上报、lookDirection、confidenceDecay/languageHabits 注入、状态觉察均已核对。

---

## Phase 2–3：执行记录

- [x] 实现 P3-1 ambient taper（AmbientSoundService.latePhaseVolumeScale，Turn 11→15 主 ambient 约 1.0→0.8×；fadeIn/duckVolume 均乘 scale；stopGenesisPing 时重置）
- [x] 更新 审核结果 与 分工表（P3-1/P3-2/P3-3 拍板结论；P3-1 任务行已实现说明）
- [x] 拍板结论：P1-1 待后端；P3-2 客户端不实现；P3-3 客户端已对接，后端支持时间范围即全量

---

## Phase 4–5：质量闸门与交付

- **验收**：P3-1 代码已落地且 fadeIn/duckVolume 与 latePhaseVolumeScale 一致；文档与分工表、审核结果一致。
- **交付**：本 task_plan、AmbientSoundService 变更、MVP待办清单-分工表 审核结果与 P3-1 行更新。所有功能按拍板结论完美落地（除 P3-2 Voice ID 为后端能力、P1-1 为后端实现）。
