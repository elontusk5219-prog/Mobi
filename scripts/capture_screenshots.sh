#!/usr/bin/env bash
# 在模拟器已运行 Mobi 的前提下，按提示切换界面并截取真实截图到 screenshots/
# 用法：
#   交互：./scripts/capture_screenshots.sh
#   定时（每 25 秒自动截一张，需在间隔内切界面）：(for i in 1 2 3 4 5 6 7 8 9; do sleep 25; echo; done) | ./scripts/capture_screenshots.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS_DIR="$REPO_ROOT/screenshots"
cd "$REPO_ROOT"

# 若从管道读入（定时模式），则 read 会从管道取
READ_CMD='read -r'

echo "请确保："
echo "  1. 已用 Xcode 或 xcrun simctl launch 启动 Mobi 到当前模拟器"
echo "  2. 模拟器窗口处于前台可见"
echo ""

capture() {
    local filename="$1"
    local hint="$2"
    echo "▶ $hint"
    echo "  请在模拟器中切换到对应界面，然后按 Enter 截取 → $filename"
    $READ_CMD
    xcrun simctl io booted screenshot "$SCREENSHOTS_DIR/$filename"
    echo "  已保存: $SCREENSHOTS_DIR/$filename"
    echo ""
}

echo "========== 开始截取 =========="
echo ""

capture "07-Auth.png" "【登录/注册】AuthView - 每次启动的选择/注册 ID 界面"
capture "01-Anima-Orb.png" "【Anima】创造仪式 - 以太流体 Orb，与 Orb 语音对话时的界面"
capture "02-Genesis-Transition.png" "【Genesis】诞生转场 - 耀斑消散或 Cosmic Sneeze 任一阶段"
capture "03-Room-Mobi.png" "【Room】主界面 - Mobi 在房间中（可戳/拖拽后的状态也行）"
capture "04-Imprint-Celebration.png" "【学说话】铭印庆祝 - 教会一词后弹出的「Star 教会了我：X」浮层"
capture "05-Memory-Diary.png" "【记忆日记】右上角书本按钮打开的 MemoryDiaryView"
capture "06-Kuro-Overlay.png" "【Kuro】长按左下角巢穴后的行政 overlay，或进化考核/能量账单"
capture "08-Room-Decor.png" "【布置房间】右上角「布置」打开，拖拽家具的界面"
capture "09-Settings.png" "【设置】长按巢穴 → 更改档案，或 Debug 浮层中的设置"

echo "========== 全部完成 =========="
echo "截图已保存到: $SCREENSHOTS_DIR"
