#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('debug', 'release')]
    [string]$Preset = 'debug'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ── 切换到项目根目录 ──────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
Set-Location $ProjectDir

$WinPreset = "$Preset-win64"

Write-Host "==> Preset       : $WinPreset"
Write-Host "==> Project dir  : $ProjectDir"
Write-Host ""

# ── cmake configure ──────────────────────────────────────────
cmake --preset $WinPreset
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# ── cmake build ──────────────────────────────────────────────
cmake --build --preset $WinPreset
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
