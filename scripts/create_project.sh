#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_NAME="QtQuickTemplate"
DEFAULT_REPO="https://github.com/neapu/QtQuickTemplate"
DEFAULT_BRANCH="master"

# ── 参数解析（支持命令行参数或交互式输入）────────────────────
PROJECT_NAME="${1:-}"
BRANCH="${2:-}"
REPO_URL="${3:-}"

if [[ -z "$PROJECT_NAME" ]]; then
    read -rp "项目名称: " PROJECT_NAME
fi
if [[ -z "$PROJECT_NAME" ]]; then
    echo "错误: 项目名称不能为空" >&2
    exit 1
fi

if [[ -z "$BRANCH" ]]; then
    read -rp "拉取分支 [${DEFAULT_BRANCH}]: " BRANCH
    BRANCH="${BRANCH:-$DEFAULT_BRANCH}"
fi

if [[ -z "$REPO_URL" ]]; then
    read -rp "仓库地址 [${DEFAULT_REPO}]: " REPO_URL
    REPO_URL="${REPO_URL:-$DEFAULT_REPO}"
fi

# ── 克隆仓库 ─────────────────────────────────────────────────
TARGET_DIR="$PROJECT_NAME"
if [[ -e "$TARGET_DIR" ]]; then
    echo "错误: 目录 '$TARGET_DIR' 已存在" >&2
    exit 1
fi

echo ""
echo "==> 仓库地址 : $REPO_URL"
echo "==> 分支     : $BRANCH"
echo "==> 目标目录 : $TARGET_DIR"
echo ""

git clone --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"
cd "$TARGET_DIR"

# ── 替换函数：在文件中将模板名替换为新项目名 ─────────────────
replace_in_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        sed -i '' "s/${TEMPLATE_NAME}/${PROJECT_NAME}/g" "$file"
        echo "    已更新: $file"
    fi
}

echo "==> 替换项目名称: '$TEMPLATE_NAME' → '$PROJECT_NAME'"

# CMakeLists.txt（根目录）：project(QtQuickTemplate ...)
replace_in_file "CMakeLists.txt"

# src/CMakeLists.txt：URI QtQuickTemplate
replace_in_file "src/CMakeLists.txt"

# AndroidManifest.xml：package、label、lib_name
replace_in_file "src/android/AndroidManifest.xml"

echo ""
echo "==> 项目 '$PROJECT_NAME' 创建完成，位于: $(pwd)"
