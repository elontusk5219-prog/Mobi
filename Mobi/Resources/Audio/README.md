# 音频资源

将以下文件放在此文件夹中（`Resources/Audio`）：

## 通用
- **GenesisAmbient.mp3**：Genesis（Amina）阶段的背景氛围乐
- **land_thud.mp3**：Mobi 落地音效（Phase III Room 入场）
- **squeak_1.mp3**：戳击 Mobi 时的可爱音效（Phase III）

## Phase II 转场（Incarnation）
- **sfx_genesis_boom.mp3**：10s 处 stopAmbient 后 0.5s 静默再播放的 Boom 音效
- **sfx_room_ber.mp3**：切 Room 时（Cosmic Sneeze 结束后）的 Pop/BER 音效

## Cosmic Sneeze（Incarnation 化身序列）
- **sfx_vacuum_silence.mp3**：Phase 0 绝对静默 / 切断
- **sfx_spark_ignite.mp3**：Phase 1 火柴点燃感
- **sfx_shake_fur.mp3**：Phase 2 蓬松晃动
- **sfx_sneeze_cute.mp3**：Phase 3 可爱喷嚏
- **sfx_curious_gu.mp3**：Phase 4 好奇「Gu?」
- **bgm_room_ambience.mp3**：Phase 4 房间环境 + 钢琴起

代码会从 Bundle 加载；若文件不存在则静默跳过。放入后需在 Xcode 中确认已加入 Mobi target。
