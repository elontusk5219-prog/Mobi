# Mobi 预生成资产清单与提示词

> 供「Mobi资产生成」管线批量生成使用。MVP 阶段预生成一批后打包进 App 或按 user_id 投放。

---

## 一、资产清单（按套）

每套 = 1 个 Mobi 变体 × 3 阶段，共 **6 个必选文件**：

| 文件名 | 格式 | 说明 |
|--------|------|------|
| `portrait_newborn.png` | PNG，透明底 | 新生形态：无四肢、无嘴、更小更软 |
| `portrait_child.png` | PNG，透明底 | 幼年形态：短粗四肢、有嘴型、Chiikawa 风 |
| `portrait_adult.png` | PNG，透明底 | 成年形态：四肢略细、轮廓更清晰 |
| `loop_newborn_blink.mp4` | MP4，可循环 | 新生眨眼循环 |
| `loop_child_blink.mp4` | MP4，可循环 | 幼年眨眼循环 |
| `loop_adult_blink.mp4` | MP4，可循环 | 成年眨眼循环 |

**可选扩展**：`loop_*_idle.mp4`（待机呼吸）、`loop_*_speaking.mp4`（说话口型）

---

### 灵器（Soul Vessel）— 管线只生成容器

灵器是挂在 Mobi 胸前的玻璃挂坠，**人格槽进度（0–100%）由 iOS 代码动态渲染**，管线无需生成不同进度的图。

**管线负责**：生成 **瓶身容器**（仅瓶身轮廓，无皮绳；内部透明留空）。皮绳由 iOS 代码绘制，可做飘动等动效。

| 文件名 | 格式 | 说明 |
|--------|------|------|
| `soul_vessel_circle.png` | PNG，透明底 | 圆形瓶身容器（默认） |
| `soul_vessel_diamond.png` | PNG，透明底 | 菱形瓶身容器（理性型） |
| `soul_vessel_heart.png` | PNG，透明底 | 心形瓶身容器（感性型） |
| `soul_vessel_star.png` | PNG，透明底 | 星形瓶身容器（创造型） |

- **画风**：厚黑线、蜡笔描边、半透明玻璃质感（参考塞尔达血量瓶/炼金术瓶），内部为空、透明，便于 iOS 用 `fillProgress` 绘制液体填充。
- **iOS 侧**：`SoulVesselView` 使用容器图作为底层，在其上按 `slotProgress`（0–1）用代码绘制填充颜色与动态效果；皮绳亦用代码画，可做飘动等动效。

**灵器容器 prompt 模板**（仅瓶身，无挂绳）：

```
A small [shape] shaped glass bottle, standalone, no cord or necklace. 
Semi-transparent glass with soft highlights, thick black waxy outline. 
Empty inside, transparent, no liquid - just the bottle outline/shell. 
Front view, transparent background. Chibi hand-drawn style, Chiikawa aesthetic.
```

替换 `[shape]`：`round/circular` | `diamond` | `heart` | `star (5-pointed)`。

---

## 二、画风统一描述（每张图必须包含）

```
画风：厚实平滑描边（深色或黑色），平涂色块，无渐变。无像素、矢量感。
Chibi 比例（2-3 头身），大眼睛带高光、脸颊腮红。
完整身体正面站立，透明背景，易抠图。
Sanrio / 三丽鸥 或 Tamagotchi 可爱风格，画风统一。
```

---

## 三、通用提示词模板

### 3.1 阶段形态描述

| 阶段 | 形态描述（加入 prompt） |
|------|------------------------|
| **newborn** | 极简形态：无四肢、无尾巴、无嘴巴。身体为一团软萌的有机 blob，非常圆润柔软。眼睛大而简单。 |
| **child** | 幼年形态：短粗的小手小脚，Chiikawa 风格四肢。有简单嘴巴（按 mouth_shape）。头大身小，比例可爱。 |
| **adult** | 成年形态：四肢略细长，身体轮廓更清晰。头身比略拉长，整体更稳定。 |

### 3.2 身体形状 → 描述

| body_form | 英文描述 |
|-----------|----------|
| round | round, blob-like body |
| rounded_square | slightly squared, soft corners |
| triangular | pear-shaped, wider at bottom |
| oval | horizontally stretched oval |
| pear | pear-shaped, small top large bottom |
| droplet | teardrop, pointy top round bottom |
| bean | bean-shaped, curved silhouette |
| cloud | fluffy cloud-like, multiple soft bumps |
| star | star-shaped with rounded points |
| heart | heart-shaped body |
| pill | pill/capsule shape |
| potato | lumpy potato-like, irregular round |
| bell | bell-shaped, narrow top wide bottom |
| mushroom | mushroom cap with stout stem |
| bubble | bubble-like, rounded with flat bottom |
| blob | organic amorphous blob |

### 3.3 眼型 → 描述

| eye_shape | 英文描述 |
|-----------|----------|
| round | large round eyes |
| droopy | droopy, slightly sad eyes |
| line | narrow line-shaped eyes |
| sharp | sharp, alert eyes |
| gentle | soft, gentle large eyes |
| sleepy | half-closed sleepy eyes |
| dot | tiny dot eyes, minimalist |
| star | star-shaped sparkling eyes |
| heart | heart-shaped eyes |
| diamond | diamond-shaped eyes |
| crescent | crescent moon-shaped eyes |
| wide | wide open surprised eyes |
| narrow | narrow slender eyes |
| upturned | upturned corners, cheerful |
| curious | slightly tilted curious eyes |
| sparkle | round eyes with star sparkles |

### 3.4 耳朵 → 描述

| ear_type | 英文描述 |
|----------|----------|
| rabbit | long upright rabbit ears |
| hamster | small round hamster ears on sides |
| bear | round bear ears |
| cat | pointed cat ears |
| dog | floppy droopy dog ears |
| fox | large pointed fox ears |
| mouse | large round mouse ears |
| pig | tiny round pig ears |
| owl | barely visible, feather-like |
| panda | round ears with dark outline |
| sheep | curly sheep ears |
| butterfly | butterfly bow on top of head |
| leaf | leaf-shaped ears |
| star | star-shaped decorative ears |
| floppy | large floppy soft ears |
| none | no visible ears |

### 3.5 嘴型 → 描述（child/adult 仅）

| mouth_shape | 英文描述 |
|-------------|----------|
| smile | gentle upward smile |
| grin | wide cheerful grin |
| line | straight neutral line |
| calm | calm slight curve |
| gentle | soft gentle smile |

### 3.6 材质感 → 描述

| material_id | 英文描述 |
|-------------|----------|
| fuzzy_felt | fuzzy felt texture, soft and woolly |
| gummy_jelly | glossy gummy jelly, translucent bounce |
| matte_clay | matte clay, sculpted look |
| smooth_plastic | smooth plastic, clean glossy |

### 3.7 配色 palette_id → 主色

| palette_id | body_color_hex | 描述 |
|------------|----------------|------|
| dusty_rose | D4A5A5 | 灰粉色、莫兰迪玫瑰 |
| sunshine_citrus | F5D68A | 暖黄、柑橘色 |
| deep_ocean | 7B9EB0 | 灰蓝、深海色 |
| electric_neon | B8A9D4 | 淡紫、霓虹感 |
| natural_clay | D4C5B0 | 米色、陶土色 |

---

## 四、完整 prompt 组装示例

**模板**（按阶段替换 `{stage_desc}`、按 DNA 替换 `{body}`、`{eyes}`、`{ears}`、`{mouth}`、`{material}`、`{color}`）：

```
A cute chibi creature, {stage_desc}. {body} body, {eyes}, {ears}. {mouth}
{material}. Main body color #{color}. Thick crisp dark outline, flat colors, no gradients.
Smooth vector illustration, no pixel art. Large expressive eyes with white highlights, soft blush on cheeks.
Sanrio or Tamagotchi kawaii style. Full body front view, transparent background. Soft and adorable.
```

**newborn 示例**（无 mouth）：

```
A cute chibi creature, minimal newborn form: no limbs, no tail, no mouth.
Soft round blob-like body. Large round eyes, small round hamster ears on sides.
Matte clay texture. Main body color #D4C5B0. Thick crisp dark outline, flat colors,
no gradients. Smooth vector illustration, no pixel art. Large expressive eyes with white highlights, soft blush on cheeks.
Sanrio or Tamagotchi kawaii style. Full body front view, transparent background. Soft and adorable.
```

**child 示例**（有 mouth）：

```
A cute chibi creature, child form with short stubby limbs.
Round body, large round eyes, small round hamster ears. Gentle smile.
Matte clay texture. Main body color #D4C5B0. Thick crisp dark outline, flat colors,
no gradients. Smooth vector illustration, no pixel art. Large expressive eyes with white highlights, soft blush on cheeks.
Sanrio or Tamagotchi kawaii style. Full body front view, transparent background. Soft and adorable.
```

---

## 五、预生成 DNA 变体（5 套代表性格）

每套对应 6 个必选文件。建议至少预生成这 5 套，覆盖主要人格组合。

### 套 1：自然默认（natural_clay）

```json
{
  "eye_spacing": 0.5,
  "eye_scale": 1.0,
  "fuzziness": 0.1,
  "blush_opacity": 0.3,
  "eye_shape": "round",
  "ear_type": "hamster",
  "body_form": "round",
  "body_color_hex": "D4C5B0",
  "mouth_shape": "gentle",
  "palette_id": "natural_clay",
  "material_id": "matte_clay"
}
```

**Prompt 关键词**：round body, round eyes, hamster ears, gentle smile, matte clay, #D4C5B0

---

### 套 2：软萌治愈（Soft + Healing）

```json
{
  "eye_spacing": 0.55,
  "eye_scale": 1.1,
  "fuzziness": 0.35,
  "blush_opacity": 0.5,
  "eye_shape": "gentle",
  "ear_type": "rabbit",
  "body_form": "round",
  "body_color_hex": "D4A5A5",
  "mouth_shape": "smile",
  "palette_id": "dusty_rose",
  "material_id": "fuzzy_felt"
}
```

**Prompt 关键词**：round body, soft gentle eyes, rabbit ears, smile, fuzzy felt, #D4A5A5

---

### 套 3：活泼调皮（Resilient + Playful）

```json
{
  "eye_spacing": 0.45,
  "eye_scale": 1.15,
  "fuzziness": 0.2,
  "blush_opacity": 0.45,
  "eye_shape": "round",
  "ear_type": "rabbit",
  "body_form": "round",
  "body_color_hex": "F5D68A",
  "mouth_shape": "grin",
  "palette_id": "sunshine_citrus",
  "material_id": "gummy_jelly"
}
```

**Prompt 关键词**：round body, large round eyes, rabbit ears, wide grin, glossy gummy jelly, #F5D68A

---

### 套 4：内向安静（Armored + Quiet）

```json
{
  "eye_spacing": 0.6,
  "eye_scale": 0.9,
  "fuzziness": 0.08,
  "blush_opacity": 0.2,
  "eye_shape": "droopy",
  "ear_type": "bear",
  "body_form": "rounded_square",
  "body_color_hex": "D4C5B0",
  "mouth_shape": "line",
  "palette_id": "natural_clay",
  "material_id": "matte_clay"
}
```

**Prompt 关键词**：rounded square body, droopy eyes, round bear ears, straight line mouth, matte clay, #D4C5B0

---

### 套 5：冷静疏离（Defensive / deep_ocean）

```json
{
  "eye_spacing": 0.55,
  "eye_scale": 1.0,
  "fuzziness": 0.05,
  "blush_opacity": 0.15,
  "eye_shape": "sharp",
  "ear_type": "cat",
  "body_form": "rounded_square",
  "body_color_hex": "7B9EB0",
  "mouth_shape": "calm",
  "palette_id": "deep_ocean",
  "material_id": "matte_clay"
}
```

**Prompt 关键词**：rounded square body, sharp alert eyes, pointed cat ears, calm mouth, matte clay, #7B9EB0

---

## 六、房间与 Kuro 资产

| 文件名 | 格式 | 说明 |
|--------|------|------|
| `room/HomeBackground.png` | PNG，9:16 | 房间背景：温暖卧室、Chiikawa 风，左下角预留 Kuro 栖位 |
| `kuro/KuroCharacter.png` | PNG，透明底 | Kuro 行政角色：深黑几何猫头鹰、锐利描边 |

**房间 prompt**（分辨率 1440×2560，9:16 竖屏；无像素、画风统一）：

```
2D illustration, cozy bedroom interior, warm soft lighting,
Chiikawa style, thick black outline, flat colors, no gradient.
Smooth vector-like illustration, no pixel art, no 8-bit, no retro game aesthetic.
Consistent line weight and color palette throughout, unified hand-drawn marker style.
Small room with window, soft furnishings, gentle atmosphere.
Pastel tones: warm cream, soft pink, light green accents, gentle floral motifs.
Hand-drawn marker feel, full scene, no characters. Cohesive illustration.
Portrait aspect ratio 9:16, vertical orientation for mobile.
In the bottom-left corner, a subtle dark perch or shadowy shelf area
for a small guardian mascot character, seamlessly integrated.
```

**Kuro prompt**：

```
2D cartoon, dark black geometric owl-like creature, sharp edges,
floating, minimal design. Thick white outline on black body.
Simple capsule-shaped eyes, no mouth.
Front view, transparent background.
Chibi hand-drawn style, Chiikawa aesthetic.
Mysterious but cute guardian character.
```

生成命令：`python3 scripts/generate_room_kuro.py`（可选 `--dry-run`、`--skip-rembg`）。Kuro 默认做 rembg 抠图；房间背景无需抠图。

---

## 七、输出目录与命名

MVP 预生成可任选其一：

**方案 A：按变体 ID 分目录**（便于打包进 Asset Catalog）

```
output/
├── variant_default/      # 套 1
│   ├── portrait_newborn.png
│   ├── portrait_child.png
│   ├── portrait_adult.png
│   ├── loop_newborn_blink.mp4
│   ├── loop_child_blink.mp4
│   └── loop_adult_blink.mp4
├── variant_healing/      # 套 2
├── variant_playful/     # 套 3
├── variant_quiet/       # 套 4
├── variant_calm/        # 套 5
├── room/
│   └── HomeBackground.png
├── kuro/
│   └── KuroCharacter.png
└── soul_vessel/         # 灵器容器（共用，不按变体分）
    ├── soul_vessel_circle.png
    ├── soul_vessel_diamond.png
    ├── soul_vessel_heart.png
    └── soul_vessel_star.png
```

**方案 B：按 user_id**（与运行时契约一致，便于后续按用户投放）

```
output/
├── user_001/
├── user_002/
...
```

---

## 八、抠图（透明底）

管线产出若为白底，需用 **rembg** 抠图。安装：`pip install rembg onnxruntime`。首次运行会下载 u2net 模型 (~176MB)。

对已有 variant 执行抠图：
```bash
cd Mobi资产生成
python3 scripts/rembg_variant.py variant_default
```

`generate_from_list.py` 生成时已自动调用 rembg；新管线需确保 `pip install -r requirements.txt` 安装完整依赖。

---

## 九、验收 checklist

**角色资产**
- [ ] 厚黑线、平涂、无渐变
- [ ] Chibi 比例、马克笔/蜡笔手绘感
- [ ] 透明背景、易抠图
- [ ] newborn 无四肢无嘴，child 短肢有嘴，adult 轮廓更清晰
- [ ] 眨眼视频可无缝循环
- [ ] 5 套 DNA 各 6 个文件，共 30 个角色资产

**灵器容器**
- [ ] 4 种形状（circle / diamond / heart / star）各 1 张，仅瓶身无挂绳
- [ ] 瓶身内部透明留空，iOS 用代码绘制填充进度 + 皮绳（可飘动）

**房间与 Kuro**
- [ ] room/HomeBackground.png：温暖卧室、Chiikawa 风、可填充
- [ ] kuro/KuroCharacter.png：深黑几何猫头鹰、透明底、rembg 抠图
