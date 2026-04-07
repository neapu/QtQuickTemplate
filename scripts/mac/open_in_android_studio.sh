#!/usr/bin/env bash
set -euo pipefail

# ── 切换到项目根目录 ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_DIR"

BUILD_DIR="build/android"
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-23}"

# ── 环境变量校验 ──────────────────────────────────────────────
check_env() {
    if [[ -z "${!1:-}" ]]; then
        echo "错误: 未设置环境变量 $1" >&2
        exit 1
    fi
}

# ── 查找 Android Studio ───────────────────────────────────────
find_android_studio() {
    # 常见安装路径
    local candidates=(
        "/Applications/Android Studio.app"
        "$HOME/Applications/Android Studio.app"
    )
    for path in "${candidates[@]}"; do
        if [[ -d "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    # 使用 Spotlight 查找
    local found
    found=$(mdfind 'kMDItemCFBundleIdentifier == "com.google.android.studio"' 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        echo "$found"
        return 0
    fi
    return 1
}

AS_APP=$(find_android_studio || true)
if [[ -z "$AS_APP" ]]; then
    echo "错误: 未找到 Android Studio，请确认已安装" >&2
    exit 1
fi
echo "==> Android Studio: $AS_APP"

# ── 查找 Gradle 工程目录（Qt androiddeployqt 生成的 android-build）──
find_gradle_project() {
    local result=""
    while IFS= read -r f; do
        result="$(dirname "$f")"
        break
    done < <(find "$BUILD_DIR" -name "gradlew" 2>/dev/null | sort)
    echo "$result"
}

GRADLE_PROJECT=$(find_gradle_project)

# ── 未找到时自动配置并构建 ────────────────────────────────────
if [[ -z "$GRADLE_PROJECT" ]]; then
    echo "==> 未找到 Android 项目，开始自动创建..."
    echo ""

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
    echo ""

    # 使用 qt-cmake 配置（自动携带 Qt toolchain，无需手动指定 -DCMAKE_TOOLCHAIN_FILE）
    "$QT_CMAKE" \
        -S "$PROJECT_DIR" \
        -B "$BUILD_DIR" \
        -DANDROID_SDK_ROOT="$ANDROID_HOME" \
        -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" \
        -DANDROID_ABI="$ANDROID_ABI" \
        -DANDROID_PLATFORM="$ANDROID_PLATFORM"

    # 构建以触发 androiddeployqt 生成 Gradle 工程
    cmake --build "$BUILD_DIR"

    GRADLE_PROJECT=$(find_gradle_project)
    if [[ -z "$GRADLE_PROJECT" ]]; then
        echo "错误: 构建完成但仍未找到 Gradle 工程（gradlew），请检查构建输出" >&2
        exit 1
    fi
fi

echo "==> Gradle 工程  : $GRADLE_PROJECT"
echo ""

open -a "$AS_APP" "$GRADLE_PROJECT"
echo "已在 Android Studio 中打开。"
