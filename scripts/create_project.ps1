#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ProjectName = '',
    [string]$Branch      = '',
    [string]$RepoUrl     = 'https://github.com/neapu/QtQuickTemplate'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$TemplateName  = 'QtQuickTemplate'
$DefaultBranch = 'master'

# ── 参数交互 ─────────────────────────────────────────────────
if (-not $ProjectName) {
    $ProjectName = (Read-Host '项目名称').Trim()
}
if (-not $ProjectName) {
    Write-Error '错误: 项目名称不能为空'
    exit 1
}

if (-not $Branch) {
    $BranchInput = (Read-Host "拉取分支 [$DefaultBranch]").Trim()
    $Branch = if ($BranchInput) { $BranchInput } else { $DefaultBranch }
}

# ── 克隆仓库 ─────────────────────────────────────────────────
$TargetDir = $ProjectName
if (Test-Path $TargetDir) {
    Write-Error "错误: 目录 '$TargetDir' 已存在"
    exit 1
}

Write-Host ""
Write-Host "==> 仓库地址 : $RepoUrl"
Write-Host "==> 分支     : $Branch"
Write-Host "==> 目标目录 : $TargetDir"
Write-Host ""

git clone --branch $Branch $RepoUrl $TargetDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# clone 完成后立即把绝对路径算好，不依赖后续的工作目录状态
$AbsTargetDir = (Resolve-Path $TargetDir).Path
Set-Location $AbsTargetDir

# ── 替换项目名称 ─────────────────────────────────────────────
function Update-ProjectName([string]$RelPath) {
    # 用 Join-Path 拼出绝对路径，与任何工作目录设置无关
    $AbsPath = Join-Path $AbsTargetDir $RelPath
    if (Test-Path $AbsPath) {
        $content = [System.IO.File]::ReadAllText($AbsPath, [System.Text.Encoding]::UTF8)
        $content = $content -replace [regex]::Escape($TemplateName), $ProjectName
        [System.IO.File]::WriteAllText(
            $AbsPath,
            $content,
            (New-Object System.Text.UTF8Encoding $false)   # 无 BOM
        )
        Write-Host "    已更新: $RelPath"
    }
}

Write-Host "==> 替换项目名称: '$TemplateName' → '$ProjectName'"

Update-ProjectName 'CMakeLists.txt'
Update-ProjectName 'src\android\AndroidManifest.xml'

Write-Host ""
Write-Host "==> 项目 '$ProjectName' 创建完成，位于: $((Get-Location).Path)"
