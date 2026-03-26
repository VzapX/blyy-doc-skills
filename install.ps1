<#
.SYNOPSIS
    安装 blyy-skills-doc 技能到目标项目
.DESCRIPTION
    自动检测目标项目使用的 AI 工具，将技能复制到对应的目录结构中。
    支持 Gemini、Codex、Cursor、Claude Code。
.PARAMETER TargetProject
    目标项目的根目录路径
.PARAMETER Skills
    要安装的技能列表，默认安装全部。可选值：blyy-init-docs, blyy-doc-sync
.PARAMETER Tool
    指定 AI 工具，跳过自动检测。可选值：gemini, claude, cursor, all
.EXAMPLE
    .\install.ps1 -TargetProject "C:\my-project"
.EXAMPLE
    .\install.ps1 -TargetProject "C:\my-project" -Tool claude
.EXAMPLE
    .\install.ps1 -TargetProject "C:\my-project" -Skills blyy-init-docs
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetProject,

    [string[]]$Skills = @("blyy-init-docs", "blyy-doc-sync"),

    [ValidateSet("gemini", "claude", "cursor", "all", "")]
    [string]$Tool = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsSourceDir = Join-Path $ScriptDir "skills"

# --- Validate ---
if (-not (Test-Path $TargetProject)) {
    Write-Error "目标项目不存在: $TargetProject"
    exit 1
}

foreach ($skill in $Skills) {
    $skillPath = Join-Path $SkillsSourceDir $skill
    if (-not (Test-Path $skillPath)) {
        Write-Error "技能不存在: $skill (路径: $skillPath)"
        exit 1
    }
}

# --- Detect AI Tools ---
function Detect-AITools {
    param([string]$ProjectPath)

    $detected = @()

    # Gemini / Codex / Cursor (.agents/)
    if ((Test-Path (Join-Path $ProjectPath ".agents")) -or
        (Test-Path (Join-Path $ProjectPath ".gemini")) -or
        (Test-Path (Join-Path $ProjectPath "AGENTS.md"))) {
        $detected += "gemini"
    }

    # Cursor (.cursor/)
    if (Test-Path (Join-Path $ProjectPath ".cursor")) {
        $detected += "cursor"
    }

    # Claude Code (.claude/)
    if ((Test-Path (Join-Path $ProjectPath ".claude")) -or
        (Test-Path (Join-Path $ProjectPath "CLAUDE.md"))) {
        $detected += "claude"
    }

    # Default to gemini if nothing detected
    if ($detected.Count -eq 0) {
        Write-Host "[INFO] 未检测到已有 AI 工具配置，默认使用 .agents/skills/ (兼容 Gemini/Codex/Cursor)" -ForegroundColor Yellow
        $detected += "gemini"
    }

    return $detected
}

function Get-SkillTargetDir {
    param([string]$ToolName, [string]$ProjectPath)

    switch ($ToolName) {
        "gemini"  { return Join-Path $ProjectPath ".agents\skills" }
        "cursor"  { return Join-Path $ProjectPath ".agents\skills" }  # Cursor 也支持 .agents/skills/
        "claude"  { return Join-Path $ProjectPath ".claude\skills" }
        default   { return Join-Path $ProjectPath ".agents\skills" }
    }
}

# --- Main ---
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       blyy-skills-doc 安装工具           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$tools = @()
if ($Tool -eq "all") {
    $tools = @("gemini", "claude")
}
elseif ($Tool -ne "") {
    $tools = @($Tool)
}
else {
    $tools = Detect-AITools -ProjectPath $TargetProject
}

Write-Host "[INFO] 目标项目: $TargetProject" -ForegroundColor Gray
Write-Host "[INFO] 检测到的工具: $($tools -join ', ')" -ForegroundColor Gray
Write-Host "[INFO] 要安装的技能: $($Skills -join ', ')" -ForegroundColor Gray
Write-Host ""

$installedCount = 0

foreach ($tool in $tools) {
    $targetDir = Get-SkillTargetDir -ToolName $tool -ProjectPath $TargetProject

    foreach ($skill in $Skills) {
        $source = Join-Path $SkillsSourceDir $skill
        $dest = Join-Path $targetDir $skill

        if (Test-Path $dest) {
            Write-Host "[SKIP] $skill -> $dest (已存在，跳过)" -ForegroundColor Yellow
            continue
        }

        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Copy-Item -Path "$source\*" -Destination $dest -Recurse -Force

        $fileCount = (Get-ChildItem -Recurse -File $dest).Count
        Write-Host "[OK]   $skill -> $dest ($fileCount 个文件)" -ForegroundColor Green
        $installedCount++
    }
}

Write-Host ""
if ($installedCount -gt 0) {
    Write-Host "✅ 安装完成！共安装 $installedCount 个技能。" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步：" -ForegroundColor White
    Write-Host "  1. 使用 blyy-init-docs 初始化项目文档（在 AI 工具中提及该技能名即可）" -ForegroundColor Gray
    Write-Host "  2. 后续代码变更时，blyy-doc-sync 会自动提醒更新文档" -ForegroundColor Gray
}
else {
    Write-Host "⚠️  没有新技能被安装（可能全部已存在）。" -ForegroundColor Yellow
}
