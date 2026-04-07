# QtQuickTemplate

基于 Qt Quick 的跨平台项目模板，支持桌面（macOS/Windows）和 Android。

## 创建新项目

使用以下命令从 GitHub 直接拉取模板并创建新项目：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/neapu/QtQuickTemplate/master/scripts/create_project.sh)
```

或通过命令行参数一次性指定（项目名、分支、仓库地址）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/neapu/QtQuickTemplate/master/scripts/create_project.sh) MyApp
```

```bash
# 拉取 android 分支
bash <(curl -fsSL https://raw.githubusercontent.com/neapu/QtQuickTemplate/master/scripts/create_project.sh) MyApp android
```

## 分支说明

| 分支 | 内容 |
|------|------|
| `master` | 桌面端（macOS / Windows） |
| `android` | 在 master 基础上新增 Android 支持 |
