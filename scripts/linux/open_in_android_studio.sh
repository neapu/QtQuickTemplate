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

# ── 查找 Android Studio ───────────────────────────────────────
find_android_studio() {
    if command -v studio.sh &>/dev/null; then
        echo "studio.sh"
        return 0
    fi
    if command -v android-studio &>/dev/null; then
        echo "android-studio"
        return 0
    fi
    if command -v studio &>/dev/null; then
        echo "studio"
        return 0
    fi
    local candidates=(
        "/opt/android-studio/bin/studio.sh"
        "/usr/local/android-studio/bin/studio.sh"
        "$HOME/android-studio/bin/studio.sh"
        "$HOME/Android/android-studio/bin/studio.sh"
        "/snap/android-studio/current/android-studio/bin/studio.sh"
    )
    for path in "${candidates[@]}"; do
        if [[ -f "$path" && -x "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

AS_SH=$(find_android_studio || true)
if [[ -z "$AS_SH" ]]; then
    echo "错误: 未找到 Android Studio，请确认已安装" >&2
    echo "      方法 1: 将 studio.sh 加入 PATH" >&2
    echo "      方法 2: 安装到常见路径:" >&2
    echo "        - /opt/android-studio/bin/studio.sh" >&2
    echo "        - ~/android-studio/bin/studio.sh" >&2
    echo "        - /snap/android-studio/current/android-studio/bin/studio.sh" >&2
    exit 1
fi
echo "==> Android Studio: $AS_SH"

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

    "$QT_CMAKE" \
        -S "$PROJECT_DIR" \
        -B "$BUILD_DIR" \
        -DANDROID_SDK_ROOT="$ANDROID_HOME" \
        -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" \
        -DANDROID_ABI="$ANDROID_ABI" \
        -DANDROID_PLATFORM="$ANDROID_PLATFORM"

    cmake --build "$BUILD_DIR"

    GRADLE_PROJECT=$(find_gradle_project)
    if [[ -z "$GRADLE_PROJECT" ]]; then
        echo "错误: 构建完成但仍未找到 Gradle 工程（gradlew），请检查构建输出" >&2
        exit 1
    fi
fi

echo "==> Gradle 工程  : $GRADLE_PROJECT"
echo ""

"$AS_SH" "$GRADLE_PROJECT" &
echo "已在 Android Studio 中打开。"
