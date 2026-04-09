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
Set-Location $TargetDir
# 同步 .NET 进程工作目录，确保 [System.IO.File] 等方法路径正确
[System.Environment]::CurrentDirectory = (Get-Location).Path

# ── 替换项目名称 ─────────────────────────────────────────────
function Update-ProjectName([string]$FilePath) {
    if (Test-Path $FilePath) {
        $AbsPath = (Resolve-Path $FilePath).Path
        $content = [System.IO.File]::ReadAllText($AbsPath, [System.Text.Encoding]::UTF8)
        $content = $content -replace [regex]::Escape($TemplateName), $ProjectName
        [System.IO.File]::WriteAllText(
            $AbsPath,
            $content,
            (New-Object System.Text.UTF8Encoding $false)   # 无 BOM
        )
        Write-Host "    已更新: $FilePath"
    }
}

Write-Host "==> 替换项目名称: '$TemplateName' → '$ProjectName'"

Update-ProjectName 'CMakeLists.txt'
Update-ProjectName 'src\android\AndroidManifest.xml'

Write-Host ""
Write-Host "==> 项目 '$ProjectName' 创建完成，位于: $((Get-Location).Path)"
