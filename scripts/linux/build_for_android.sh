#!/usr/bin/env bash
set -euo pipefail

# ── 切换到项目根目录 ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_DIR"

BUILD_DIR="build/android"
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-23}"

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

ABI_DIR_NAME="${ANDROID_ABI//-/_}"
QT_CMAKE="$QT_DIR/android_${ABI_DIR_NAME}/bin/qt-cmake"

if [[ ! -f "$QT_CMAKE" ]]; then
    echo "错误: qt-cmake 不存在: $QT_CMAKE" >&2
    echo "      请确认 QT_DIR 是否正确（应指向 Qt 版本根目录，如 /opt/Qt/6.8.0）" >&2
    exit 1
fi

echo "==> qt-cmake     : $QT_CMAKE"
echo "==> Android SDK  : $ANDROID_HOME"
echo "==> Android NDK  : $ANDROID_NDK_ROOT"
echo "==> ABI          : $ANDROID_ABI"
echo "==> Platform     : $ANDROID_PLATFORM"
echo "==> Project dir  : $PROJECT_DIR"
echo ""

# ── cmake configure ──────────────────────────────────────────
"$QT_CMAKE" \
    -S "$PROJECT_DIR" \
    -B "$BUILD_DIR" \
    -DANDROID_SDK_ROOT="$ANDROID_HOME" \
    -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" \
    -DANDROID_ABI="$ANDROID_ABI" \
    -DANDROID_PLATFORM="$ANDROID_PLATFORM"

# ── cmake build ──────────────────────────────────────────────
cmake --build "$BUILD_DIR"

# ── 复制 APK 到 bin 目录 ──────────────────────────────────────
PROJECT_NAME=$(grep -m1 'project(' "$PROJECT_DIR/CMakeLists.txt" | sed 's/project(\([^ )]*\).*/\1/')
APK_SRC=$(find "$BUILD_DIR" -name "*.apk" 2>/dev/null | sort | head -1)
if [[ -n "$APK_SRC" ]]; then
    mkdir -p "$PROJECT_DIR/bin"
    cp "$APK_SRC" "$PROJECT_DIR/bin/${PROJECT_NAME}.apk"
    echo ""
    echo "==> APK 已复制到: bin/${PROJECT_NAME}.apk"
else
    echo ""
    echo "警告: 未找到 APK 文件，跳过复制步骤" >&2
fi

echo ""
echo "==> 构建完成: $BUILD_DIR"
