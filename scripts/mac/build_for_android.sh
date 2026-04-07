#!/usr/bin/env bash
set -euo pipefail

# ── 环境变量校验 ─────────────────────────────────────────────
check_env() {
    if [[ -z "${!1:-}" ]]; then
        echo "错误: 未设置环境变量 $1" >&2
        exit 1
    fi
}

check_env QT_DIR
check_env ANDROID_HOME
check_env ANDROID_NDK_ROOT

# ── 路径推导 ─────────────────────────────────────────────────
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-23}"

# arm64-v8a → arm64_v8a（Qt Android 目录命名规则）
ABI_DIR_NAME="${ANDROID_ABI//-/_}"
TOOLCHAIN_FILE="$QT_DIR/android_${ABI_DIR_NAME}/lib/cmake/Qt6/qt.toolchain.cmake"

if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
    echo "错误: Qt Android toolchain 文件不存在:" >&2
    echo "      $TOOLCHAIN_FILE" >&2
    echo "      请确认 QT_DIR 是否正确（应指向 Qt 版本根目录，如 /opt/Qt/6.8.0）" >&2
    exit 1
fi

# ── 切换到项目根目录 ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_DIR"

echo "==> Qt toolchain : $TOOLCHAIN_FILE"
echo "==> Android SDK  : $ANDROID_HOME"
echo "==> Android NDK  : $ANDROID_NDK_ROOT"
echo "==> ABI          : $ANDROID_ABI"
echo "==> Platform     : $ANDROID_PLATFORM"
echo "==> Project dir  : $PROJECT_DIR"
echo ""

# ── cmake configure（使用 android preset）────────────────────
cmake --preset android

# ── cmake build（使用 android preset）───────────────────────
cmake --build --preset android
