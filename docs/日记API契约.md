# 日记 API 契约

**用途：** 明确「昨日日记」能力的数据来源与接口约定，供记忆模块按契约对接；若后续需独立日记/摘要后端，可在此扩展。

**维护：** 与 [MVP-Phase-Plan](MVP-Phase-Plan.md)、[Mobi全栈白皮书](Mobi全栈白皮书.md)、[MemoryDiaryService](Mobi/Services/Network/MemoryDiaryService.swift) 同步。

---

## 1. 当前实现（无需新后端）

**结论：** MVP 下**不需要**新的日记专用后端接口；日记数据来自现有 **EverMemOS GET /api/v0/memories/search**，客户端 [MemoryDiaryService.fetchYesterdaySummary](Mobi/Services/Network/MemoryDiaryService.swift) 已按此契约实现。

### 1.1 契约（客户端 → EverMemOS）

| 项目 | 约定 |
|------|------|
| **接口** | EverMemOSClient.searchMemories(...) → 对应 GET /api/v0/memories/search；认证 Authorization: Bearer &lt;api_key&gt; |
| **query** | 固定或可配置，当前为 `"总结昨天与用户的对话和互动"` |
| **user_id** | EverMemOSMemoryService.currentUserId |
| **group_id** | EverMemOSMemoryService.currentGroupId（可选） |
| **retrieve_method** | `"hybrid"` |
| **memory_types** | `["episodic_memory"]` |
| **top_k** | 5（日记条数） |
| **start_time / end_time** | 昨日 0:00 ~ 今日 0:00（UTC），ISO8601 格式 |

### 1.2 响应与客户端映射

- **响应**：EverMemOS 返回 memories（episodic_memory 数组），每项含 `content`、`summary`、`timestamp` 等（见 [EverMemOSMemoryItem](Mobi/Services/Network/EverMemOSClient.swift)）。
- **映射**：MemoryDiaryService 取每条的 `summary ?? content`，trim 后作为 DiaryEntry.bullets；若无结果则回退 mock（「暂无记录」或占位文案）。
- **展示**：[MemoryDiaryView](Mobi/Features/Room/Views/MemoryDiaryView.swift) 调用 `fetchYesterdaySummary()`，展示 date + bullets + sentiment。

### 1.3 记忆模块对接要点

- 记忆模块**无需改动**：日记入口即 `MemoryDiaryService.fetchYesterdaySummary()`，数据源为 EverMemOS search；只要 EverMemOS 支持按 user_id + start_time/end_time 检索并返回 summary/content，日记即可用。
- 若 EverMemOS 增加或变更 search 参数（如 date 快捷、summary 必填），仅需在 MemoryDiaryService 与本文档中同步参数与映射即可。

---

## 2. 可选：独立日记/摘要接口（若产品需要）

若后续希望由**后端统一做昨日回顾摘要**（如 LLM 汇总成一段话或结构化摘要），可新增专用接口，客户端优先调该接口，失败或未配置时再回退到 §1 的 EverMemOS search。

### 2.1 建议端点与报文（供后端实现参考）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/diary/yesterday` 或 `/user/{userId}/diary/yesterday` | 返回昨日日记摘要 |

**响应体建议：**

```json
{
  "date": "2024-02-13",
  "summary": "可选：一段话总述",
  "bullets": ["要点1", "要点2", "要点3"],
  "sentiment": "heart"
}
```

- **date**：昨日日期（YYYY-MM-DD）。
- **summary**：可选，后端生成的单段摘要。
- **bullets**：列表，与当前 DiaryEntry.bullets 一致；可由后端从 EverMemOS 拉取当日记忆后再汇总或原样返回。
- **sentiment**：可选，与现有 DiarySentiment 对齐（sun / moon / heart）。

### 2.2 客户端对接方式

- MemoryDiaryService 可增加 `fetchYesterdaySummaryFromDiaryAPI()`：若配置了 diary API baseURL 则 GET 该端点，解析为 DiaryEntry；否则或请求失败时，继续使用现有 EverMemOS search 逻辑（§1）。
- 记忆模块仍只依赖 `MemoryDiaryService.fetchYesterdaySummary()` 对外接口不变，内部实现在「专用 API」与「EverMemOS search」之间二选一或分级回退即可。

---

## 3. 相关文档与代码

| 文档/代码 | 路径 |
|-----------|------|
| MVP-Phase-Plan | docs/MVP-Phase-Plan.md |
| Mobi 全栈白皮书 | docs/Mobi全栈白皮书.md |
| MemoryDiaryService | Mobi/Services/Network/MemoryDiaryService.swift |
| EverMemOSClient | Mobi/Services/Network/EverMemOSClient.swift |
| MemoryDiaryView | Mobi/Features/Room/Views/MemoryDiaryView.swift |
| 施工顺序表 | docs/施工顺序表.md |
