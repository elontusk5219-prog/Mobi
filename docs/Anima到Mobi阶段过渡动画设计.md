# Anima → Mobi 阶段过渡动画设计

**项目**: Mobi — Genesis Evolution (The Singularity Sequence)  
**目标**: 10 秒高保真电影级过渡 [Nebula → Singularity → Mobi]  
**触发时机**: Genesis 满足出生条件（如 7 次交互 / The Snap）后，替代当前短时 Snap 白闪，播放本过渡再进入 Room。

---

## 1. 时间轴总览

| 时间 | 阶段 | 视觉主题 | 触觉 |
|------|------|----------|------|
| 0–3s | Phase 1 | 星云弥散 (Nebula Dispersion) | — |
| 3–7s | Phase 2 | 绝对奇点 (Absolute Singularity) | 持续增强压迫感 |
| 7s | 奇点瞬间 | 白洞 + 视觉留白 | 震动骤停（真空期） |
| 7–7.5s | — | 真空期 | 无 |
| 7.5s | Phase 3 起点 | 引力波脉冲 | 一记清脆 Transient |
| 7–10s | Phase 3 | 维度重塑，Mobi 显现 | 可选轻触觉 |

---

## 2. Phase 1：星云弥散 (0–3s)

### 2.1 视觉

- **粒子系统**：10 万+ 粒子，置于 3D 坐标空间（可投影到 2D 屏幕或真 3D 渲染）。
- **背景**：纯黑 (#000000)，作为「可呼吸」的宇宙底。
- **粒子外观**：生物发光感（Bioluminescent glow）  
  - 建议：高亮度、低饱和度色（如青/紫/白），带 1–2px 光晕或 soft blend。
- **动力学**：布朗运动（Brownian motion），用 **Simplex Noise** 驱动位移，模拟气体/流体弥散，避免完全随机带来的噪点感。

### 2.2 技术要点

- **Noise**：需 Simplex/Perlin 3D 噪声（当前工程仅有 `NoiseGenerator` 的 2D 随机 alpha 纹理，需新增或接入 Metal/Accelerate 的噪声）。
- **坐标**：粒子位置 `p(t) = p0 + ∫ noise(p, t) dt` 或离散步进；速度可由噪声梯度推导。
- **性能**：若 100k 粒子全在 CPU 会吃力，Phase 1 建议 GPU Compute 或 FBO 管线（见第 5 节）。

### 2.3 与现有 Genesis 的衔接

- 过渡开始时，可将当前 Amina 视图（NebulaSoulView + 背景）作为「最后一帧」，然后切到本粒子场景；或用当前帧导出为纹理，再渐隐为粒子场。

---

## 3. Phase 2：绝对奇点 (3–7s)

### 3.1 动力学

- **中心引力源**：所有粒子向场景中心 `(0,0,0)`（或屏幕中心）加速汇聚。
- **加速度**：建议与距离的平方成反比（或 `1/r`）以模拟引力，形成「吸入」感；速度随接近中心急剧增大。

### 3.2 Shader 逻辑（优先实现）

- **Stretch 效果**：  
  - 沿粒子**速度方向**拉伸粒子（如从圆点拉成椭圆或线段）。  
  - 拉伸比例与「到中心的距离」相关：越近中心，拉伸越强，形成运动模糊/相对论拉长感。  
  - 公式思路：`scaleAlongVelocity = 1 + k * (1 - distanceToCenter / maxDistance)`，k 为强度。

- **引力透镜 (Gravitational Lensing)**：  
  - 用**极坐标扭曲**对背景时空采样：以中心为原点，半径 `r` 处的采样偏移量随 `r` 变化（例如 `r' = r + lensStrength/r` 或类似），使背景（纯黑 + 远处粒子）沿径向弯曲。  
  - 实现方式：全屏后处理 shader，UV 从直角坐标转极坐标 → 扭曲半径 → 再转回 UV 采样。

### 3.3 白洞与视觉留白（关键心理诱饵）

- **Whiteout Point**：粒子到达中心时，在极小区间内过渡到「极高密度白点」。  
  - 做法：当粒子 `distanceToCenter < ε` 时，不绘制粒子，改为在中心累加一个高亮度、高模糊的白色光斑，强度随时间在 3→7s 内递增，在 7s 达到最大。
- **负压/吞噬**：在 7s 瞬间，  
  - 所有背景噪声、UI 元素、边缘残留粒子被「吞噬」：  
  - 实现：全屏快速向中心收缩的遮罩（或径向 alpha 从外到内归零），或全屏在极短时间内（如 0.1–0.2s）切到纯白/极亮，形成**极度寂静**的视觉留白，为 Phase 3 的「Mobi 出现」做铺垫。

### 3.4 触觉

- **3s–7s**：持续增强的 Haptic 震动（Continuous），模拟引力压迫感。  
  - 强度/锐度从低到高线性或曲线递增，与粒子向中心汇聚的节奏一致。
- **7s**：震动**突然停止**（真空期开始）。

---

## 4. Phase 3：维度重塑 (7–10s)

### 4.1 中心实体：Mobi 的「身体」

- **渲染方式**：用 **Raymarching** 在中心绘制 Mobi 的形体（避免复杂网格，便于变形与风格化）。
- **几何建议 — 卡拉比-丘流形 (Calabi-Yau)**：  
  - 卡拉比-丘流形顶点建模会带来性能灾难，因此**用 SDF（符号距离函数）做数学描述**。  
  - 通过调节 SDF 的 **Deformation parameters**（如扭曲、缩放、多孔结构），在 7–10s 内从「奇点」平滑变形为可识别的有机体，呈现「跨维度绽放」的平滑感。
- **材质**：  
  - 液态晶体感（Liquid crystal texture）。  
  - **Fresnel 反射**：视线与法线夹角越大（掠射）反射越强。  
  - **内部折射**：半透明内部折射，可结合简单次表面散射或折射系数。

### 4.2 全屏折射与引力波涟漪

- **Refraction Map**：全屏后处理，从中心向外辐射的「引力波」涟漪。  
  - 思路：以中心为圆心的同心圆状位移场，位移量随半径与时间变化（如 `sin(k*r - ω*t)` 衰减），对「残留星云粒子 + 背景」做折射/位移采样。  
  - 效果：Mobi 出现时，残余粒子与空间被涟漪「推开」，强化从奇点中诞生的感觉。
- **与 Raymarching 的配合**：先渲染 Raymarching 的 Mobi 体，再在其上叠加全屏折射，折射可带轻微色散（chromatic aberration）增强质感。

### 4.3 触觉

- **7.5s**：一记清脆的 **Transient** 脉冲（引力波触觉化），与屏幕上的引力波扩散同步。
- **7–10s**：可选：Mobi 轮廓稳定后轻量连续或单次触觉，避免打扰。

---

## 5. 性能与实现约束

### 5.1 GPU 与管线

- **FBO（Frame Buffer Objects）**：  
  - 粒子物理/位置更新与粒子绘制**分离**：用 Compute Shader 或 Fragment 写入 FBO 更新位置/速度，再用另一 Pass 读 FBO 绘制粒子，保证 60fps 下稳定。
- **Phase 2**：非视觉后台任务（如网络、复杂业务逻辑）在 3–7s 内节流，保证 GPU/CPU 留给坍缩动画。

### 5.2 帧率与画质

- 全程目标 **60fps**。  
- 若设备过热或帧率掉到阈值以下，可动态降低粒子数量或关闭折射/透镜的某一层。

### 5.3 色彩与 Banding

- 除背景纯黑外，**禁止使用低比特深度导致的色带**：粒子颜色、光晕、白洞、Mobi 材质均使用高比特深度（如 HDR 或 10-bit 输出），或 dithering 减轻 banding。

---

## 6. 触觉时间表（汇总）

| 时间 | 事件 | 类型 | 说明 |
|------|------|------|------|
| 3s | 引力开始 | Continuous 开始 | 强度从低起，逐渐升高 |
| 3–7s | 持续压迫 | Continuous | 强度/锐度递增 |
| 7s | 奇点/白洞 | 停止 | 所有 Haptic 骤停，视觉留白 |
| 7–7.5s | 真空期 | 无 | 静默 |
| 7.5s | 引力波 | Transient | 单次清脆脉冲，与画面涟漪同步 |
| 7.5–10s | 可选 | 轻 Transient/Continuous | 随 Mobi 稳定可加一次轻反馈 |

可与现有 `SnapHapticService` 扩展：例如新增 `playSingularitySequence(duration: 4.0)`（3–7s 持续）、`playGravityWavePulse()`（7.5s 单次），并在统一时间轴上由过渡动画驱动调用。

---

## 7. 与现有工程的衔接点

- **触发**：当前 `triggerBirth()` 在 `MobiEngine` 中调用，`GenesisCoordinatorView` 的 `onComplete` 在 `lifeStage == .newborn` 时执行并 `showRoom = true`。  
  - 设计上可在「满足出生条件」时先不切 `lifeStage`，而是启动本 10s 过渡动画；动画结束时再执行 `triggerBirth()` 与 `onComplete()`，这样 Room 出现时正好是「Mobi 已诞生」的完整叙事。
- **视图层级**：过渡动画建议为全屏独立 View（或 ViewController），覆盖在 Genesis 之上；动画结束后移除并显示 Room + feather white 淡出（保留现有逻辑）。

---

## 8. 实现路径选型（待定）

| 方案 | 优点 | 缺点 |
|------|------|------|
| **A. Metal 全管线** | 100k 粒子、FBO、Raymarching、SDF、复杂 Shader 均可实现，画质与性能可控 | 工作量大，需 Metal 着色器与渲染架构 |
| **B. SwiftUI/Canvas 简化版** | 与现有 AminaView/GenesisVisuals 一致，迭代快 | 粒子数量需大幅减少（如 2k–5k），无真 Raymarching，SDF 需用预烘焙或简化几何近似；无 FBO，物理与绘制可能同线程 |
| **C. SceneKit/Unity 等** | 可快速搭粒子与后处理 | 引入额外依赖与包体，与现有 SwiftUI 集成需桥接 |

建议：若产品目标为「高保真电影级」，选 **A** 并分阶段实现（先粒子+引力+Stretch，再透镜+白洞，最后 Raymarching+SDF+Mobi）；若先验证叙事与节奏，可做 **B** 的简化版（少粒子 + 简化奇点 + 2D 精灵式「Mobi」出现），再逐步替换为 Metal 管线。

---

## 9. 文档修订

- 初版：根据提示词与关键细节补遗整理时间轴、三阶段视觉/Shader/触觉及实现约束。  
- 待产品/设计确认：Phase 3 中「Mobi 身体」的最终形态是抽象 Calabi-Yau 风格还是更具体的角色轮廓；以及实现路径选型（A/B/C）。
