<#
Claude Code 全自动安装 + 自动适配DeepSeek V4 Pro[1m]
修复版：解决乱码和括号不匹配问题
#>
Add-Type -AssemblyName Microsoft.VisualBasic
Clear-Host

# Claude Code 最低要求 Node >= 18.17.0
$nodeMinVer = [version]"18.17.0"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Windows Claude Code 全自动安装 DeepSeek版 " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

#region 1. 检测并安装 Git
Write-Host "🔍 正在检测 Git..." -ForegroundColor Yellow
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    Write-Host "✅ Git 已存在，跳过安装" -ForegroundColor Green
}
else {
    Write-Host "🔽 未检测到 Git，开始自动安装..." -ForegroundColor Yellow
    winget install Git.Git -s winget
}
#endregion

#region 2. 检测并安装 Node.js
Write-Host "`n🔍 正在检测 Node.js (最低要求 $nodeMinVer)..." -ForegroundColor Yellow
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $verRaw = & node -v
    if ($verRaw -match 'v(\d+\.\d+\.\d+)') {
        $currVer = [version]$matches[1]
        Write-Host "当前 Node 版本：$currVer"
        if ($currVer -ge $nodeMinVer) {
            Write-Host "✅ Node 版本达标，跳过安装" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Node 版本过低，自动安装 LTS 新版..." -ForegroundColor Red
            winget install OpenJS.NodeJS.LTS -s winget
        }
    }
}
else {
    Write-Host "🔽 未检测到 Node.js，开始自动安装..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS -s winget
}
#endregion

# 刷新系统环境变量
refreshenv | Out-Null

#region 3. 安装 Claude Code CLI
Write-Host "`n🔽 开始安装 Claude Code CLI..." -ForegroundColor Yellow
irm https://claude.ai/install.ps1 | iex
Write-Host "✅ Claude Code CLI 安装完成" -ForegroundColor Green
#endregion

#region 4. 自动修复 PATH 环境变量（永久用户级）
$claudeBinPath = Join-Path $env:USERPROFILE ".claude\local"
$userEnvPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if (-not $userEnvPath.Contains($claudeBinPath)) {
    $newUserPath = "$userEnvPath;$claudeBinPath"
    [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
    Write-Host "`n✅ 已自动写入 Claude 到用户环境变量 PATH" -ForegroundColor Green
}

# 立即刷新当前终端PATH
$env:PATH = [Environment]::GetEnvironmentVariable("PATH","User") + ";" + [Environment]::GetEnvironmentVariable("PATH","Machine")
#endregion

#region 5. 弹窗图形输入 DeepSeek API Key
Write-Host "`n🔑 即将弹出窗口，请输入 DeepSeek API Key..." -ForegroundColor Yellow
$apiKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "请输入你的 DeepSeek sk- 开头 API 密钥",
    "DeepSeek API Key 配置",
    "sk-"
)

# 校验密钥格式
if ([string]::IsNullOrWhiteSpace($apiKey) -or $apiKey -notlike "sk-*") {
    Write-Host "`n❌ API Key 为空或格式错误，退出配置！" -ForegroundColor Red
    pause
    exit
}
#endregion

#region 6. 写入 PowerShell 永久配置
$baseUrl = "https://api.deepseek.com/anthropic"
$modelName = "deepseek-v4-pro`[1m`]"
$timeoutMs = "600000"
$profilePath = $PROFILE

$profileContent = @"
# 自动配置 Claude Code 接入 DeepSeek V4 Pro[1m]
`$env:ANTHROPIC_BASE_URL = "$baseUrl"
`$env:ANTHROPIC_AUTH_TOKEN = "$apiKey"
`$env:ANTHROPIC_MODEL = "$modelName"
`$env:API_TIMEOUT_MS = "$timeoutMs"
`$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
"@

if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
}
Add-Content -Path $profilePath -Value "`n$profileContent" -Encoding utf8
#endregion

# 完成提示
Write-Host "`n=============================================" -ForegroundColor Green
Write-Host "✅ 全部安装 + 环境变量 + DeepSeek 配置完成！" -ForegroundColor Green
Write-Host "🤖 默认模型：deepseek-v4-pro[1m]" -ForegroundColor Cyan
Write-Host "📌 关闭当前窗口，新开终端输入 claude 即可使用" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Green
pause
