# Mock 与硬编码清单

**用途：** 汇总所有「Mock 响应」「fallback 默认值」「硬编码文案/ID」的位置与用途，便于排查与生产配置。文档与代码变更后需同步更新本清单。

---

## 1. 凭据类（Secrets.swift）

| 变量 | 默认值（未配置 env 时） | 说明 |
|------|------------------------|------|
| `DOUBAO_APP_ID` | `8712004137` | 火山引擎 Doubao 应用 ID；**生产必须用环境变量覆盖** |
| `DOUBAO_TOKEN` | `D_p5xzb...` | Doubao 访问 Token；同上 |
| `DOUBAO_SECRET_KEY` | `8bQzkMU-...` | Doubao Secret Key；同上 |
| `JIEKOU_AI_API_KEY` | `sk_KBncy-...` | 接口AI API Key（entropy / Soul / Visual DNA）；同上 |
| `everMemOSAPIKey` | `""` | 无默认，未配置时记忆静默降级 |
| `everMemOSBaseURL` | `https://api.evermind.ai` | 云端默认；本地自部署可改为 `http://localhost:1995` |
| `profileEvolutionBaseURL` | `""` | 无默认，未配置时画像用 Mock |

**约定：** 代码内默认值为本地开发便利；生产环境必须在 Scheme 或 xcconfig 中设置环境变量，且勿提交真实值。见 `Config/README-Secrets.md`。

---

## 2. Mock 响应（契约约定，未配置/失败时使用）

| 位置 | 触发条件 | 内容/行为 |
|------|----------|-----------|
| **EvolutionProfileService.mockResponse()** | 未配置 `PROFILE_EVOLUTION_BASE_URL`、URL 非法、请求失败、非 200、解码失败 | 契约 §5.1：lifeStage=newborn, slotProgress=0.2, completeness=0.25（便于未接画像时走幼年乱码语等流程）, dimensionConfidences 固定五维，confidenceDecay=false, unlockedFeatures=[] |
| **backend/index.js mockResponse()** | 未配置 `EVERMEMOS_API_KEY` 或无 `userId` | 同上 JSON，后端直接返回 |
| **MemoryDiaryService.mockDiaryEntry(date)** | EverMemOS 未配置、请求失败、或检索结果为空 | 固定三条 bullets：「你们聊到了今天的天气和心情。」「Mobi 表达了对新房间的喜爱。」「你们约定明天再见。」+ sentiment=.heart |
| **MemoryDiaryService** 检索结果 bullets 为空 | EverMemOS 有返回但无有效 summary/content | 单条 `["暂无记录"]` |

以上为设计内降级，配置好对应服务后即走真实数据。

---

## 3. 视觉 / 配置 Fallback（非 Mock 数据）

| 位置 | 用途 |
|------|------|
| **ResolvedMobiConfig.fallback** | 未从 API 拿到 config 时（如切换账号进 Room、JumpToRoom）用默认颜色 |
| **MobiVisualDNA.default** | API 失败或无 transcript 时由 PersonalityToDNAMapper / 默认值提供外形 |
| **MobiColorPalette.fallback** | 色板解析失败或无效时用 .oat |
| **GenesisVideoFallbackView** | genesis_transition.mp4 缺失时显示径向光晕渐变 |
| **GenesisViewModel.applyFallbackConfig()** | StrongModelSoulService/Gemini 失败时用 SoulProfile 本地推导 DNA |
| **ProceduralMobiView** | dna == nil 时用 default + primaryColor |

均为「缺资源/失败时保底展示」，非业务 Mock。

---

## 4. 其他硬编码

| 位置 | 值 | 说明 |
|------|-----|------|
| **DoubaoRealtimeService** | `user_id` 为空时用 `"mobi_tester"` | 仅当 `UserIdentityService.currentUserId.isEmpty` 时；正常登录后为当前用户 ID |
| **DoubaoRealtimeService** | `X-Api-Client-Version: "1"` | 固定版本头，可接受 |
| **JIEKOU_AI_DEEPSEEK_MODEL** | `"deepseek/deepseek-r1-0528"` | 模型 ID 固定 |
| **JIEKOU_AI_SOUL_MODEL** | `"gemini-2.5-flash"` | 模型 ID 固定 |
| **MemoryDiaryView** | 文案「暂无记录」 | 当 fetchYesterdaySummary 返回 nil 时（如 task 未完成或异常） |
| **backend** | `MEMORY_COUNT_FOR_FULL = 40`、`THRESHOLD_A/B` | 画像完整度计算常数，可后续改为配置 |

---

## 5. 文档中「Mock/未实现」描述更新情况

- **画像服务**：后端已实现（`backend/`），配置 `PROFILE_EVOLUTION_BASE_URL` 即可从 Mock 切到真实 API。
- **日记**：已对接 EverMemOS search（时间范围检索）；仅当未配置 Key 或检索无结果时回退 mock 文案或 mockDiaryEntry。
- **language_habits**：EvolutionProfileResponse 已支持；画像后端未扩展时返回 nil，客户端传 nil 不注入。

---

## 6. 检查清单（发布前）

- [ ] 生产环境所有凭据均来自环境变量，无使用 Secrets 代码内默认值
- [ ] `PROFILE_EVOLUTION_BASE_URL`、`EVERMEMOS_API_KEY` 已配置（若需真实画像与记忆）
- [ ] 需区分账号的请求（画像、记忆、行为）均携带或使用 `currentUserId`
- [ ] 无将真实 API Key/Token 提交进仓库
