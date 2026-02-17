# Mobi 项目认知对齐文档

> 如果你是 AI，需要快速了解 Mobi 项目，读这篇就够了。

**管线 portrait 同步**：构建前需将管线产出复制到 Asset Catalog。在工程根执行 `python3 scripts/sync_portrait_to_assets.py`，或直接 Build（Build Phase 会自动执行）。

---

## 🎯 一句话概括

**Mobi 是一个 AI 伴侣应用**，不是普通 App，而是一个有灵魂的「活体」。用户通过 15 轮对话「召唤」Mobi，Mobi 会记住用户、成长、进化，从幼年→青年→成年。

---

## 📊 当前进度（2026-02）

**目标：** 2026年春节上线 MVP

### 已完成 ✅

| 模块 | 状态 |
|------|------|
| Anima 阶段（15轮对话） | ✅ 完成 |
| Genesis 转场动画 | ✅ 完成 |
| Room 房间交互 | ✅ 完成 |
| 人格槽（灵器） | ✅ 完成 |
| 进化机制客户端 | ✅ 完成 |
| Doubao 实时语音接入 | ✅ 完成 |
| 记忆日记 | ✅ 完成 |
| MobiBrain 大脑驱动 | ✅ 完成 |

### 进行中 🔄

- 用户注册/登录系统
- 硬件原型设计
- 3C 认证申请
- 域名备案

### 待开始 ⏳

- 内测（50台工程机）
- 公测（1000人）
- 正式上线

---

## 🧠 核心概念

### 三个阶段

| 阶段 | 说明 | 行为特征 |
|------|------|----------|
| **Anima** | 创世阶段，用户通过 15 轮对话「召唤」Mobi | 神秘、魔法仪式感 |
| **Genesis** | 转世过渡，动画转场从光球变成实体 | Cosmic Sneeze 动画 |
| **Room** | 日常生活阶段，陪伴用户 | 幼年/青年/成年不同行为 |

### 进化机制

- **驱动**：用户画像完整度（EverMemOS）
- **阈值**：A=0.5（幼年→青年）、B=0.8（青年→成年）
- **原则**：只进不退

### 人格槽（Soul Vessel）

- 瓶身填充度 = 用户画像完整度
- 满溢 → 进化考核 → 裂纹 → 炸裂 → 胸口印记

### 记忆

- **出生记忆**：来自 15 轮 transcript（但不注入 Room 对话）
- **日记**：EverMemOS 存储与检索

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────┐
│                    iOS Client                        │
├─────────────────────────────────────────────────────┤
│  Anima UI  │  Genesis  │  Room UI  │  MobiBrain   │
│  (Fluid)   │  (Video)   │  (3D)     │  (状态驱动)   │
├─────────────────────────────────────────────────────┤
│            Doubao Realtime Voice                     │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                    Backend                           │
├─────────────────────────────────────────────────────┤
│  GenesisCommitAPI  →  StrongModel (Gemini)          │
│  产出：visual_dna, persona, memories               │
├─────────────────────────────────────────────────────┤
│  EverMemOS (记忆与画像服务)                          │
└─────────────────────────────────────────────────────┘
```

### 技术栈

- **前端**：SwiftUI + Metal Shader
- **语音**：Doubao 实时语音 API
- **后端**：Node.js / Gemini API
- **存储**：EverMemOS

---

## 📁 关键文件位置

```
/Volumes/cursor/Mobi/
├── docs/                           # 所有文档
│   ├── 项目文档索引.md              # 文档目录
│   ├── Mobi完整指南-关于Mobi的一切.md  # 入门必读
│   ├── MVP-Phase-Plan.md          # 阶段计划
│   └── MVP待办清单-分工表.md       # 任务分工
├── Mobi/                          # iOS 代码
│   ├── Core/
│   │   ├── MobiEngine.swift       # 核心引擎
│   │   ├── MobiBrain.swift        # 大脑驱动
│   │   └── MobiVisualDNA.swift    # 视觉 DNA
│   ├── Features/
│   │   ├── AminaFluidView.swift   # Anima 流体
│   │   ├── RoomContainerView.swift # Room 房间
│   │   └── ProceduralMobiView.swift # Mobi 实体
│   └── Services/
│       ├── DoubaoRealtimeService.swift  # 语音
│       ├── EvolutionManager.swift       # 进化
│       └── MemoryDiaryService.swift    # 记忆
└── backend/                        # 后端代码
```

---

## 🔑 关键接口

### 画像接口

```json
// 客户端请求画像
GET /api/evolution/profile?user_id=xxx

// 返回
{
  "completeness": 0.65,
  "lifeStage": "child",
  "personalitySlotProgress": 0.65,
  "confidenceDecay": 0.3,
  "languageHabits": {...}
}
```

### Genesis Commit

```json
POST /api/genesis/commit
{
  "transcript": [...],  // 15轮对话
  "user_id": "xxx"
}

// 返回
{
  "visual_dna": {...},
  "persona": "性格描述...",
  "memories": [...]
}
```

---

## 📝 常用命令/操作

### 开发

```bash
# 打开项目
open /Volumes/cursor/Mobi/Mobi.xcodeproj

# 运行
Cmd + R in Xcode
```

### 测试

```bash
# 切换不同阶段（Debug）
- newborn: 画像完整度 < 0.5
- child: 0.5 <= 完整度 < 0.8  
- adult: 完整度 >= 0.8
```

---

## ⚠️ 注意事项

1. **Anima 遗忘**：Mobi 出生后不记得 Anima 对话内容（设计约束）
2. **只进不退**：进化不可逆，画像完整度只增不减
3. **依赖后端**：部分功能需要 EverMemOS 画像服务部署后才能完全生效

---

## 📚 深入学习

1. **入门** → `Mobi完整指南-关于Mobi的一切.md`
2. **进度** → `MVP-Phase-Plan.md`
3. **任务** → `MVP待办清单-分工表.md`
4. **设计** → `Mobi交互行为完整设计.md`
5. **画像** → `Mobi用户画像与进化驱动设计.md`
6. **资产生成** → `Mobi资产生成系统规格.md`（独立项目「Mobi资产生成」实现，共用文件夹对接）

---

## 📞 如何贡献

1. 阅读文档了解当前进度
2. 查看 `MVP待办清单-分工表.md` 认领任务
3. 代码修改后更新对应文档
4. 确保通过审核（代码 + 文档一致性）

---

*最后更新：2026-02-16*
