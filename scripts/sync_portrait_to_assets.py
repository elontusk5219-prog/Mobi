#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""将管线 output 下的 portrait、room、kuro 复制到 Asset Catalog imageset。
在 Mobi 工程根执行: python3 scripts/sync_portrait_to_assets.py"""

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PIPELINE_OUTPUT = ROOT / "../Mobi资产生成/output"
XCASSETS = ROOT / "Mobi/Assets.xcassets"

# (源相对路径, 目标 imageset 名)
ASSETS = [
    # portrait (variant_default)
    ("variant_default/portrait_newborn.png", "MobiPortraitNewborn", "portrait_newborn.png"),
    ("variant_default/portrait_child.png", "MobiPortraitChild", "portrait_child.png"),
    ("variant_default/portrait_adult.png", "MobiPortraitAdult", "portrait_adult.png"),
    # room
    ("room/HomeBackground.png", "HomeBackground", "HomeBackground.png"),
    # kuro
    ("kuro/KuroCharacter.png", "KuroCharacter", "KuroCharacter.png"),
]


def main():
    pipeline = PIPELINE_OUTPUT.resolve()
    if not pipeline.exists():
        print(f"[sync] 管线输出目录不存在: {pipeline}")
        print("请先运行管线生成资产。")
        return 1
    for rel_src, imageset, dst_filename in ASSETS:
        src = pipeline / rel_src
        dst_dir = XCASSETS / f"{imageset}.imageset"
        dst = dst_dir / dst_filename
        if src.exists():
            dst_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            print(f"[sync] {rel_src} -> {imageset}.imageset")
        else:
            print(f"[sync] 跳过（不存在）: {rel_src}")
    print("[sync] 完成。请在 Xcode 中 Product → Clean Build Folder，然后 Build。")
    return 0


if __name__ == "__main__":
    exit(main())
