#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ── 切换到项目根目录 ──────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
Set-Location $ProjectDir

# ── 检查 adb 是否可用 ─────────────────────────────────────────
$Adb = $null
if (Get-Command adb -ErrorAction SilentlyContinue) {
    $Adb = 'adb'
} elseif ($env:ANDROID_HOME -and (Test-Path "$env:ANDROID_HOME\platform-tools\adb.exe")) {
    $Adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
} else {
    Write-Error "错误: 找不到 adb，请将 `$ANDROID_HOME\platform-tools 加入 PATH"
    exit 1
}

# ── 查找 APK ─────────────────────────────────────────────────
$BuildDir = 'build\android'
$ApkFiles = @(Get-ChildItem -Path $BuildDir -Filter '*.apk' -Recurse -ErrorAction SilentlyContinue |
    Sort-Object FullName | Select-Object -ExpandProperty FullName)

if ($ApkFiles.Count -eq 0) {
    Write-Error "错误: 在 $BuildDir 下未找到 APK，请先执行 build_for_android.ps1"
    exit 1
}

if ($ApkFiles.Count -eq 1) {
    $Apk = $ApkFiles[0]
} else {
    Write-Host "找到多个 APK，请选择:"
    for ($i = 0; $i -lt $ApkFiles.Count; $i++) {
        Write-Host "  [$($i+1)] $($ApkFiles[$i])"
    }
    $ApkIdx = Read-Host "输入编号 [1-$($ApkFiles.Count)]"
    if ($ApkIdx -notmatch '^\d+$' -or [int]$ApkIdx -lt 1 -or [int]$ApkIdx -gt $ApkFiles.Count) {
        Write-Error "错误: 无效编号"
        exit 1
    }
    $Apk = $ApkFiles[[int]$ApkIdx - 1]
}

Write-Host "==> APK: $Apk"
Write-Host ""

# ── 获取已连接设备列表 ────────────────────────────────────────
$DeviceLines = & $Adb devices | Select-Object -Skip 1 |
    Where-Object { $_ -match '\bdevice$' } |
    ForEach-Object { ($_ -split '\s+')[0] }
$Devices = @($DeviceLines)

if ($Devices.Count -eq 0) {
    Write-Error "错误: 未检测到已连接的 Android 设备，请通过 USB 连接设备并启用 USB 调试"
    exit 1
}

if ($Devices.Count -eq 1) {
    $Device = $Devices[0]
    Write-Host "==> 设备: $Device"
} else {
    Write-Host "检测到多个设备，请选择:"
    for ($i = 0; $i -lt $Devices.Count; $i++) {
        $Model = (& $Adb -s $Devices[$i] shell getprop ro.product.model 2>$null) -replace '\r', '' | Select-Object -First 1
        if (-not $Model) { $Model = '未知型号' }
        Write-Host "  [$($i+1)] $($Devices[$i])  ($Model)"
    }
    $DevIdx = Read-Host "输入编号 [1-$($Devices.Count)]"
    if ($DevIdx -notmatch '^\d+$' -or [int]$DevIdx -lt 1 -or [int]$DevIdx -gt $Devices.Count) {
        Write-Error "错误: 无效编号"
        exit 1
    }
    $Device = $Devices[[int]$DevIdx - 1]
}

Write-Host "==> 安装到设备: $Device"
Write-Host ""

# ── 安装 APK ─────────────────────────────────────────────────
& $Adb -s $Device install -r $Apk
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "安装完成。"
