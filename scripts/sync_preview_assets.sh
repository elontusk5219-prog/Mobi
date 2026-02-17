#!/usr/bin/env bash
# 将管线 variant_default 同步到 App 的 preview 目录，便于预览效果。
# 在 Mobi 工程根目录执行: bash scripts/sync_preview_assets.sh
#
# 若要同步到自己的账号，在设置中查看用户 ID 后执行:
#   bash ../Mobi资产生成/scripts/sync_assets_to_app.sh . "你的user_id" ../Mobi资产生成/output variant_default

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBI_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PIPELINE_SCRIPT="$(cd "$MOBI_ROOT/../Mobi资产生成/scripts" 2>/dev/null && pwd)/sync_assets_to_app.sh"
PIPELINE_OUTPUT="${1:-$MOBI_ROOT/../Mobi资产生成/output}"

if [ ! -f "$PIPELINE_SCRIPT" ]; then
  echo "[sync] 未找到管线脚本，请确保 Mobi资产生成 与 Mobi 同层" >&2
  exit 1
fi

bash "$PIPELINE_SCRIPT" "$MOBI_ROOT" "preview" "$PIPELINE_OUTPUT" "variant_default"
