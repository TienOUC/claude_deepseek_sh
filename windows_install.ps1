<#
Windows 一键安装 Claude Code CLI + 国内镜像
自动弹窗输入 DeepSeek APIKey 自动接入 V4 Pro[1m]
#>

# 弹窗输入框依赖
Add-Type -AssemblyName Microsoft.VisualBasic
Clear-Host

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Windows Claude Code 国内镜像一键安装     " -ForegroundColor Cyan
Write-Host "      自动接入 DeepSeek V4 Pro[1m]          " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ===================== 0. 自动安装 Git + Node.js（Claude Code 依赖）=====================
function Refresh-PathEnv {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetCmd) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "🔽 正在安装 Git..." -ForegroundColor Yellow
        & winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
        Refresh-PathEnv
    } else {
        Write-Host "✓ Git 已安装，跳过" -ForegroundColor DarkGray
    }
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "🔽 正在安装 Node.js LTS..." -ForegroundColor Yellow
        & winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
        Refresh-PathEnv
    } else {
        Write-Host "✓ Node.js 已安装，跳过" -ForegroundColor DarkGray
    }
} else {
    Write-Host "⚠️ 未检测到 winget，无法自动安装 Git/Node。请从以下地址手动安装后再运行本脚本：" -ForegroundColor Yellow
    Write-Host "   Git: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "   Node.js LTS: https://nodejs.org/" -ForegroundColor Yellow
    Write-Host ""
}

# ===================== 1. 国内镜像安装 Claude Code =====================
Write-Host "🔽 开始国内镜像安装 Claude Code CLI..." -ForegroundColor Yellow
# 改用国内加速镜像安装脚本
irm https://cdn.jsdelivr.net/gh/claude/claude-install/install.ps1 | iex

Write-Host "✅ Claude Code 安装完成" -ForegroundColor Green
Write-Host ""

# ===================== 2. 弹窗输入 DeepSeek API Key =====================
$apiKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "请输入你的 DeepSeek sk- 开头 API 密钥",
    "DeepSeek API Key",
    "sk-"
)

# 校验
if ([string]::IsNullOrWhiteSpace($apiKey) -or $apiKey -eq "sk-" -or $apiKey -notlike "sk-*") {
    Write-Host "❌ API Key 无效，退出配置" -ForegroundColor Red
    Read-Host "按回车退出"
    exit
}

# ===================== 3. 固定配置 =====================
$baseUrl = "https://api.deepseek.com/anthropic"
# Windows 安全带完整括号
$modelName = "deepseek-v4-pro`[1m`]"
$timeout   = "600000"

# ===================== 4. 写入 PowerShell 全局配置 =====================
$profilePath = $PROFILE

$cfg = @"
# 国内镜像安装 - Claude Code 对接 DeepSeek V4 Pro[1m]
`$env:ANTHROPIC_BASE_URL = "$baseUrl"
`$env:ANTHROPIC_AUTH_TOKEN = "$apiKey"
`$env:ANTHROPIC_MODEL = "$modelName"
`$env:API_TIMEOUT_MS = "$timeout"
`$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
"@

if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
}
Add-Content -Path $profilePath -Value "`n$cfg" -Encoding utf8

# ===================== 5. 完成提示 =====================
Write-Host ""
Write-Host "✅ 全部配置完成！" -ForegroundColor Green
Write-Host "🤖 已设置模型：deepseek-v4-pro[1m]" -ForegroundColor Cyan
Write-Host "📌 请关闭当前 PowerShell，重新打开输入 claude 即可使用" -ForegroundColor Yellow
Write-Host ""
Read-Host "按回车关闭窗口"