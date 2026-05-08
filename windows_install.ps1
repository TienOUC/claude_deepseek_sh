<#
Claude Code + DeepSeek V4 Pro[1m] 全自动安装
强制 PowerShell 运行 | 智能检测 Git/Node | 自动修复环境变量
#>
Add-Type -AssemblyName Microsoft.VisualBasic
Clear-Host

$nodeMinVer = [version]"18.17.0"

Write-Host "=============================================" -F Cyan
Write-Host "  Claude Code 全自动安装 · DeepSeek 专用版  " -F Cyan
Write-Host "=============================================" -F Cyan
Write-Host ""

# 1. 检测 Git
Write-Host "🔍 检测 Git..." -F Yellow
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "✅ Git 已安装" -F Green
}
else {
    Write-Host "🔽 安装 Git..." -F Yellow
    winget install Git.Git -s winget --accept-source-agreements --accept-package-agreements
}

# 2. 检测 Node
Write-Host "`n🔍 检测 Node.js (最低版本: $nodeMinVer)..." -F Yellow
if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = & node -v
    if ($v -match 'v(\d+\.\d+\.\d+)') {
        $curr = [version]$matches[1]
        Write-Host "当前 Node 版本: $curr"
        if ($curr -ge $nodeMinVer) {
            Write-Host "✅ Node 版本符合" -F Green
        }
        else {
            winget install OpenJS.NodeJS.LTS -s winget --accept-source-agreements --accept-package-agreements
        }
    }
}
else {
    winget install OpenJS.NodeJS.LTS -s winget --accept-source-agreements --accept-package-agreements
}

# 刷新环境变量
if (Get-Command refreshenv -ErrorAction SilentlyContinue) { refreshenv | Out-Null }

# 3. 安装 Claude CLI
Write-Host "`n🔽 安装 Claude Code CLI..." -F Yellow
irm https://claude.ai/install.ps1 | iex
Write-Host "✅ Claude Code 安装完成" -F Green

# 4. 自动修复 PATH
$claudePath = Join-Path $env:USERPROFILE ".claude\local"
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if (-not $userPath.Contains($claudePath)) {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;$claudePath", "User")
    Write-Host "✅ 已添加 Claude 到环境变量" -F Green
}

$env:PATH = [Environment]::GetEnvironmentVariable("PATH","User") + ";" + [Environment]::GetEnvironmentVariable("PATH","Machine")

# 5. 弹窗输入 API Key
Write-Host "`n🔑 正在弹出 API Key 输入窗口..." -F Yellow
$apiKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "请输入 DeepSeek API Key（sk-开头）",
    "DeepSeek API Key",
    "sk-"
)

if (-not $apiKey -or $apiKey -notlike "sk-*") {
    Write-Host "`n❌ 无效 API Key" -F Red
    pause
    exit
}

# 6. 写入配置
$profilePath = $PROFILE
$cfg = @"
# Claude Code → DeepSeek V4 Pro[1m]
`$env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
`$env:ANTHROPIC_AUTH_TOKEN = "$apiKey"
`$env:ANTHROPIC_MODEL = 'deepseek-v4-pro[1m]'
`$env:API_TIMEOUT_MS = "600000"
`$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
"@

if (-not (Test-Path $profilePath)) { New-Item -Path $profilePath -Type File -Force | Out-Null }
Add-Content -Path $profilePath -Value "`n$cfg" -Encoding UTF8

Write-Host "`n=============================================" -F Green
Write-Host "✅ 安装完成！关闭终端重新输入 claude 即可使用" -F Green
Write-Host "=============================================" -F Green
pause
