# Mobi 界面截图

本目录存放 Mobi App 各阶段的界面截图，用于 README 与文档展示。

## 截图清单

| 文件名 | 说明 | 拍摄时机 |
|--------|------|----------|
| `01-Anima-Orb.png` | Anima 创造仪式，以太流体 Orb | 与 Orb 语音对话中，Orb 有颜色/形态变化 |
| `02-Genesis-Transition.png` | Genesis 诞生转场 | 耀斑消散或 Cosmic Sneeze 任一阶段 |
| `03-Room-Mobi.png` | Room 主界面，Mobi 在房间中 | Mobi 落地后，可展示戳击/拖拽后的状态 |
| `04-Imprint-Celebration.png` | 学说话铭印庆祝 | 教会一词后弹出的「Star 教会了我：X」浮层 |
| `05-Memory-Diary.png` | 记忆日记 | 右上角书本按钮打开 MemoryDiaryView |
| `06-Kuro-Overlay.png` | Kuro 规则守护者 | 长按巢穴后的行政 overlay，或进化考核/能量账单 |
| `07-Auth.png` | 登录/注册 | 每次启动的 AuthView，选择或注册 ID |
| `08-Room-Decor.png` | 布置房间 | 右上角「布置」打开 RoomDecorView，拖拽家具 |
| `09-Settings.png` | 设置 | 长按巢穴 → 更改档案，或 Debug 浮层中的设置 |

## 拍摄建议

1. **设备**：iPhone 15 Pro 或同代模拟器，深色模式与浅色模式各备一份（可选）。
2. **分辨率**：建议 1170×2532（6.5"）或 1290×2796（6.7"），便于 README 展示。
3. **模拟器截图**：
   ```bash
   # 启动模拟器并运行 App 后
   xcrun simctl io booted screenshot screenshots/01-Anima-Orb.png
   ```
4. **真机**：⌘+S 或 侧边键+音量上 截屏，再拖入本目录并重命名。

## 占位图

若尚未拍摄，可暂时用项目内资产作为占位：
- `Mobi/Assets.xcassets/HomeBackground.imageset/HomeBackground.png` → Room 背景
- `Mobi/Assets.xcassets/MobiPortraitNewborn.imageset/portrait_newborn.png` → Mobi 肖像
- `Mobi/Assets.xcassets/KuroCharacter.imageset/KuroCharacter.png` → Kuro 角色

复制到本目录并重命名即可临时填充 README 截图区域。
