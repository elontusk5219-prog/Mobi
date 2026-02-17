# Mobi资产生成 output 审核报告

**审核时间**：基于当前 output 目录与管线代码  
**规格依据**：[Mobi预生成资产清单与提示词](Mobi预生成资产清单与提示词.md)

---

## 一、当前 output 概况

```
output/
└── default/
    ├── prompt_newborn.txt
    ├── prompt_child.txt
    └── prompt_adult.txt
```

**结论**：当前只有 `default/` 下的 3 个 prompt 文本，**无任何 PNG、MP4 或灵器资产**。

---

## 二、问题清单

### 1. 未执行完整生成流程

- **现象**：仅有 `prompt_*.txt`，说明执行的是 `--dry-run` 或类似逻辑，只写 prompt 未调用文生图 API。
- **规格要求**：5 套 variant（各 6 文件）+ 4 张灵器容器。
- **建议**：配置 `ARK_API_KEY` 后执行：
  ```bash
  python3 scripts/generate_from_list.py              # 全量
  python3 scripts/generate_from_list.py --skip-video   # 仅图 + 灵器
  ```

---

### 2. 预期目录结构缺失

**规格要求**：

| 目录 | 应含文件 |
|------|----------|
| `output/variant_default/` | portrait_newborn/child/adult.png, loop_*_blink.mp4 |
| `output/variant_healing/` | 同上 |
| `output/variant_playful/` | 同上 |
| `output/variant_quiet/` | 同上 |
| `output/variant_calm/` | 同上 |
| `output/soul_vessel/` | soul_vessel_circle/diamond/heart/star.png |

**当前**：上述目录均不存在；仅有 `output/default/`（来自 `cli.py --user-id default`，非 `generate_from_list`）。

---

### 3. default 与 variant 混用

- `output/default/` 来自 `cli.py` 的默认 `--user-id default`。
- 规格中预生成清单使用 `variant_default`、`variant_healing` 等。
- **建议**：若用 `generate_from_list.py`，会输出 `variant_*`；若用 `cli.py` 手动跑，应显式 `--user-id variant_default` 等，或统一以 `generate_from_list` 为准。

---

### 4. 眨眼视频透明通道

- `video_gen.py` 中 `frames.append(np.array(out_img.convert("RGB")))`，眨眼视频为 **不透明 RGB**。
- 原图若为透明底，生成 MP4 后会变成不透明背景（一般为黑或白）。
- **影响**：若 Room 需透明底循环视频叠在背景上，当前实现无法满足。
- **可选**：维持 RGB（适合有背景的场景）；若需透明，可考虑 WebM+VP9 或 PNG 序列。

---

### 5. 眨眼区域硬编码

```python
# video_gen.py
x0, y0 = int(w * 0.2), int(h * 0.15)
x1, y1 = int(w * 0.8), int(h * 0.30)
```

- 眼区假设在图上 15%–30% 高度、20%–80% 宽度。
- 对大部分 Chibi 站立可能适用，但不同 body_form（如 heart、star）或构图变化时可能不准。
- **建议**：先按现有逻辑跑，若眨眼位置偏移明显，再考虑按 body_form 或简单规则调整区域。

---

### 6. 两套生成脚本职责不清

| 脚本 | user_id 格式 | 用途 |
|------|--------------|------|
| `generate_mvp_assets.py` | mvp_resilient_playful 等 | persona（shell_type + personality_base） |
| `generate_from_list.py` | variant_default 等 | DNA 直接，对齐预生成清单 |

- README 推荐 MVP 用 `generate_from_list`，与预生成清单一致。
- **建议**：以 `generate_from_list.py` 为预生成主流程；`generate_mvp_assets.py` 可作为 persona 路径的补充。

---

### 7. 灵器与 variant 放置层级

- 规格：灵器放在 `output/soul_vessel/`（共用，不按变体分）。
- `generate_from_list.py` 已按此实现。
- **结论**：结构合理，待实际执行后确认文件是否产出。

---

## 三、prompt 质量抽查（output/default）

当前 3 个 prompt 与规格基本一致：

- 画风： thick black outline, flat solid colors, chibi, marker/crayon
- newborn：no limbs, no mouth ✓
- child：stubby limbs, Chiikawa style, gentle smile ✓
- adult：more defined shape ✓
- 材质与配色：matte clay, natural clay beige ✓

**说明**：`persona_to_prompt`（经由 `mapping.soul_profile_to_assets`）与 `generate_from_list` 的 `build_creature_prompt`（DNA 直接）在表述上略有差异，但语义一致，可接受。

---

## 四、整改建议（按优先级）

1. **立即**：确认 `.env` 中 `ARK_API_KEY` 有效，执行 `python3 scripts/generate_from_list.py` 完成全量生成。
2. **验证**：检查 `output/variant_*/` 与 `output/soul_vessel/` 是否均有对应文件，且尺寸/格式符合需求。
3. **后续**：若需透明底眨眼视频，评估 WebM 或 PNG 序列方案；若眼区不准，再调整 `video_gen` 的眼区参数。

---

## 五、预期完整 output 结构（生成成功后）

```
output/
├── variant_default/
│   ├── portrait_newborn.png
│   ├── portrait_child.png
│   ├── portrait_adult.png
│   ├── loop_newborn_blink.mp4
│   ├── loop_child_blink.mp4
│   └── loop_adult_blink.mp4
├── variant_healing/
│   └── (同上)
├── variant_playful/
├── variant_quiet/
├── variant_calm/
├── soul_vessel/
│   ├── soul_vessel_circle.png
│   ├── soul_vessel_diamond.png
│   ├── soul_vessel_heart.png
│   └── soul_vessel_star.png
└── default/          # 若曾用 cli.py 跑过，可保留或删除
    └── prompt_*.txt
```
