#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('arm64-v8a', 'x86_64', 'armeabi-v7a', 'x86')]
    [string]$Abi,
    [string]$Platform
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ── 切换到项目根目录 ──────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
Set-Location $ProjectDir

$BuildDir        = 'build\android'
$AndroidAbi      = if ($Abi)      { $Abi }      elseif ($env:ANDROID_ABI)      { $env:ANDROID_ABI }      else { 'arm64-v8a' }
$AndroidPlatform = if ($Platform) { $Platform } elseif ($env:ANDROID_PLATFORM) { $env:ANDROID_PLATFORM } else { 'android-23' }

# ── 环境变量校验 ─────────────────────────────────────────────
function Assert-Env([string]$Name) {
    if (-not (Get-Item "env:$Name" -ErrorAction SilentlyContinue)) {
        Write-Error "错误: 未设置环境变量 $Name"
        exit 1
    }
}

Assert-Env 'QT_DIR'
Assert-Env 'ANDROID_HOME'
Assert-Env 'ANDROID_NDK_ROOT'

$AbiDirName = $AndroidAbi -replace '-', '_'
$QtCmake    = Join-Path $env:QT_DIR "android_$AbiDirName\bin\qt-cmake.bat"

if (-not (Test-Path $QtCmake)) {
    Write-Error "错误: qt-cmake 不存在: $QtCmake`n      请确认 QT_DIR 是否正确（应指向 Qt 版本根目录，如 C:\Qt\6.8.0）"
    exit 1
}

Write-Host "==> qt-cmake     : $QtCmake"
Write-Host "==> Android SDK  : $env:ANDROID_HOME"
Write-Host "==> Android NDK  : $env:ANDROID_NDK_ROOT"
Write-Host "==> ABI          : $AndroidAbi"
Write-Host "==> Platform     : $AndroidPlatform"
Write-Host "==> Project dir  : $ProjectDir"
Write-Host ""

# ── cmake configure ──────────────────────────────────────────
& $QtCmake `
    -G Ninja `
    -S $ProjectDir `
    -B $BuildDir `
    -DANDROID_SDK_ROOT="$env:ANDROID_HOME" `
    -DANDROID_NDK_ROOT="$env:ANDROID_NDK_ROOT" `
    -DANDROID_ABI="$AndroidAbi" `
    -DANDROID_PLATFORM="$AndroidPlatform"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# ── cmake build ──────────────────────────────────────────────
cmake --build $BuildDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# ── 复制 APK 到 bin 目录 ──────────────────────────────────────
$ProjectName = (Select-String -Path (Join-Path $ProjectDir 'CMakeLists.txt') -Pattern 'project\((\S+)' |
    Select-Object -First 1).Matches[0].Groups[1].Value

$ApkSrc = Get-ChildItem -Path $BuildDir -Filter '*.apk' -Recurse -ErrorAction SilentlyContinue |
    Sort-Object FullName | Select-Object -First 1

if ($ApkSrc) {
    $BinDir = Join-Path $ProjectDir 'bin'
    if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir | Out-Null }
    Copy-Item $ApkSrc.FullName (Join-Path $BinDir "$ProjectName.apk") -Force
    Write-Host ""
    Write-Host "==> APK 已复制到: bin\$ProjectName.apk"
} else {
    Write-Host ""
    Write-Warning "未找到 APK 文件，跳过复制步骤"
}

Write-Host ""
Write-Host "==> 构建完成: $BuildDir"
