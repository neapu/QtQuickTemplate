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

# ── 查找 Android Studio ───────────────────────────────────────
function Find-AndroidStudio {
    # 常见安装路径
    $Candidates = @(
        'C:\Program Files\Android\Android Studio\bin\studio64.exe',
        'C:\Program Files\Android\Android Studio\bin\studio.exe',
        "$env:LOCALAPPDATA\Programs\Android Studio\bin\studio64.exe",
        "$env:LOCALAPPDATA\Programs\Android Studio\bin\studio.exe"
    )
    foreach ($Path in $Candidates) {
        if (Test-Path $Path) { return $Path }
    }
    # 通过注册表查找
    $RegPaths = @(
        'HKLM:\SOFTWARE\Android Studio',
        'HKCU:\SOFTWARE\Android Studio'
    )
    foreach ($Reg in $RegPaths) {
        if (Test-Path $Reg) {
            $InstallDir = (Get-ItemProperty $Reg -ErrorAction SilentlyContinue).Path
            if ($InstallDir) {
                $Exe = Join-Path $InstallDir 'bin\studio64.exe'
                if (Test-Path $Exe) { return $Exe }
            }
        }
    }
    return $null
}

$AsExe = Find-AndroidStudio
if (-not $AsExe) {
    Write-Error "错误: 未找到 Android Studio，请确认已安装"
    exit 1
}
Write-Host "==> Android Studio: $AsExe"

# ── 查找 Gradle 工程目录（Qt androiddeployqt 生成的 android-build）──
function Find-GradleProject {
    $Gradlew = Get-ChildItem -Path $BuildDir -Filter 'gradlew.bat' -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName | Select-Object -First 1
    if ($Gradlew) { return $Gradlew.DirectoryName }
    return $null
}

$GradleProject = Find-GradleProject

# ── 未找到时自动配置并构建 ────────────────────────────────────
if (-not $GradleProject) {
    Write-Host "==> 未找到 Android 项目，开始自动创建..."
    Write-Host ""

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
    Write-Host ""

    & $QtCmake `
        -G Ninja `
        -S $ProjectDir `
        -B $BuildDir `
        -DANDROID_SDK_ROOT="$env:ANDROID_HOME" `
        -DANDROID_NDK_ROOT="$env:ANDROID_NDK_ROOT" `
        -DANDROID_ABI="$AndroidAbi" `
        -DANDROID_PLATFORM="$AndroidPlatform"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --build $BuildDir
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $GradleProject = Find-GradleProject
    if (-not $GradleProject) {
        Write-Error "错误: 构建完成但仍未找到 Gradle 工程（gradlew.bat），请检查构建输出"
        exit 1
    }
}

Write-Host "==> Gradle 工程  : $GradleProject"
Write-Host ""

Start-Process -FilePath $AsExe -ArgumentList $GradleProject
Write-Host "已在 Android Studio 中打开。"
