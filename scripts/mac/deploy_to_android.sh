#!/usr/bin/env bash
set -euo pipefail

# ── 切换到项目根目录 ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_DIR"

# ── 检查 adb 是否可用 ─────────────────────────────────────────
if ! command -v adb &>/dev/null; then
    if [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
        ADB="$ANDROID_HOME/platform-tools/adb"
    else
        echo "错误: 找不到 adb，请将 \$ANDROID_HOME/platform-tools 加入 PATH" >&2
        exit 1
    fi
else
    ADB="adb"
fi

# ── 查找 APK ─────────────────────────────────────────────────
BUILD_DIR="build/android"
APK_FILES=()
while IFS= read -r line; do
    APK_FILES+=("$line")
done < <(find "$BUILD_DIR" -name "*.apk" 2>/dev/null | sort)

if [[ ${#APK_FILES[@]} -eq 0 ]]; then
    echo "错误: 在 $BUILD_DIR 下未找到 APK，请先执行 build_for_android.sh" >&2
    exit 1
fi

if [[ ${#APK_FILES[@]} -eq 1 ]]; then
    APK="${APK_FILES[0]}"
else
    echo "找到多个 APK，请选择:"
    for i in "${!APK_FILES[@]}"; do
        echo "  [$((i+1))] ${APK_FILES[$i]}"
    done
    read -r -p "输入编号 [1-${#APK_FILES[@]}]: " APK_IDX
    if ! [[ "$APK_IDX" =~ ^[0-9]+$ ]] || (( APK_IDX < 1 || APK_IDX > ${#APK_FILES[@]} )); then
        echo "错误: 无效编号" >&2
        exit 1
    fi
    APK="${APK_FILES[$((APK_IDX-1))]}"
fi

echo "==> APK: $APK"
echo ""

# ── 获取已连接设备列表 ────────────────────────────────────────
DEVICES=()
while IFS= read -r line; do
    DEVICES+=("$line")
done < <("$ADB" devices | awk 'NR>1 && /	device$/ {print $1}')

if [[ ${#DEVICES[@]} -eq 0 ]]; then
    echo "错误: 未检测到已连接的 Android 设备，请通过 USB 连接设备并启用 USB 调试" >&2
    exit 1
fi

if [[ ${#DEVICES[@]} -eq 1 ]]; then
    DEVICE="${DEVICES[0]}"
    echo "==> 设备: $DEVICE"
else
    echo "检测到多个设备，请选择:"
    for i in "${!DEVICES[@]}"; do
        # 尝试获取设备型号
        MODEL=$("$ADB" -s "${DEVICES[$i]}" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "未知型号")
        echo "  [$((i+1))] ${DEVICES[$i]}  ($MODEL)"
    done
    read -r -p "输入编号 [1-${#DEVICES[@]}]: " DEV_IDX
    if ! [[ "$DEV_IDX" =~ ^[0-9]+$ ]] || (( DEV_IDX < 1 || DEV_IDX > ${#DEVICES[@]} )); then
        echo "错误: 无效编号" >&2
        exit 1
    fi
    DEVICE="${DEVICES[$((DEV_IDX-1))]}"
fi

echo "==> 安装到设备: $DEVICE"
echo ""

# ── 安装 APK ─────────────────────────────────────────────────
"$ADB" -s "$DEVICE" install -r "$APK"
echo ""
echo "安装完成。"
