#!/usr/bin/env bash
set -euo pipefail

# ── 参数解析（默认 debug）────────────────────────────────────
PRESET="${1:-debug}"

if [[ "$PRESET" != "debug" && "$PRESET" != "release" ]]; then
    echo "用法: $(basename "$0") [debug|release]" >&2
    exit 1
fi

# ── 切换到项目根目录 ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_DIR"

echo "==> Preset       : $PRESET"
echo "==> Project dir  : $PROJECT_DIR"
echo ""

# ── cmake configure ──────────────────────────────────────────
cmake --preset "$PRESET"

# ── cmake build ──────────────────────────────────────────────
cmake --build --preset "$PRESET"
