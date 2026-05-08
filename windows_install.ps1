<#
Claude Code + DeepSeek V4 Pro[1m] 全自动安装
强制 PowerShell 运行 | 智能检测 Git/Node | 自动修复环境变量
最终修复版 v3: 消除 PATH 重复刷新、网络安全风险、版本检查
#>

# 检查 PowerShell 版本（Issue #6 修复）
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "❌ 此脚本需要 PowerShell 5.0 或更高版本，当前版本: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}

Add-Type -AssemblyName Microsoft.VisualBasic
Clear-Host

$nodeMinVer = [version]"18.17.0"

Write-Host "=============================================" -F Cyan
Write-Host "  Claude Code 全自动安装 · DeepSeek 专用版  " -F Cyan
Write-Host "=============================================" -F Cyan
Write-Host ""

# 0. 检查执行策略
Write-Host "🔍 检查 PowerShell 执行策略..." -F Yellow
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted") {
    Write-Host "⚠️  当前执行策略为 Restricted，尝试修改..." -F Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "✅ 执行策略已修改为 RemoteSigned" -F Green
    }
    catch {
        Write-Host "❌ 无法修改执行策略，请以管理员身份运行此脚本" -F Red
        pause
        exit 1
    }
}

# 1. 检测 Git
Write-Host "`n🔍 检测 Git..." -F Yellow
$gitInstalled = $false
try {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "✅ Git 已安装" -F Green
        $gitInstalled = $true
    }
    else {
        Write-Host "🔽 安装 Git..." -F Yellow
        $osVersion = [System.Environment]::OSVersion.Version
        
        if ($osVersion.Major -ge 10 -and $osVersion.Build -ge 22000) {
            try {
                winget install Git.Git -s winget --accept-source-agreements --accept-package-agreements -ErrorAction Stop
                Write-Host "✅ Git 已通过 winget 安装" -F Green
                $gitInstalled = $true
            }
            catch {
                Write-Host "⚠️  winget 安装失败: $_" -F Yellow
                Write-Host "   请手动从 https://git-scm.com 下载安装" -F Yellow
            }
        }
        else {
            Write-Host "⚠️  Windows 版本较低，请手动安装 Git" -F Yellow
        }
    }
}
catch {
    Write-Host "❌ Git 检测出错: $_" -F Red
}

# 2. 检测 Node
Write-Host "`n🔍 检测 Node.js (最低版本: $nodeMinVer)..." -F Yellow
$nodeInstalled = $false
try {
    $needInstall = $true
    
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $v = & node -v 2>$null
        if ($v -match 'v(\d+\.\d+\.\d+)') {
            $curr = [version]$matches[1]
            Write-Host "当前 Node 版本: $curr" -F Cyan
            if ($curr -ge $nodeMinVer) {
                Write-Host "✅ Node 版本符合" -F Green
                $needInstall = $false
                $nodeInstalled = $true
            }
            else {
                Write-Host "⚠️  Node 版本过低，需要更新..." -F Yellow
            }
        }
    }
    
    if ($needInstall) {
        Write-Host "🔽 安装/更新 Node.js LTS..." -F Yellow
        $osVersion = [System.Environment]::OSVersion.Version
        
        if ($osVersion.Major -ge 10 -and $osVersion.Build -ge 22000) {
            try {
                winget install OpenJS.NodeJS.LTS -s winget --accept-source-agreements --accept-package-agreements -ErrorAction Stop
                Write-Host "✅ Node.js 已通过 winget 安装" -F Green
                $nodeInstalled = $true
            }
            catch {
                Write-Host "⚠️  winget 安装失败: $_" -F Yellow
                Write-Host "   请手动从 https://nodejs.org 下载安装" -F Yellow
            }
        }
        else {
            Write-Host "⚠️  请手动安装 Node.js LTS" -F Yellow
        }
    }
}
catch {
    Write-Host "❌ Node 检测出错: $_" -F Red
}

# 3. 安装 Claude CLI
Write-Host "`n🔽 安装 Claude Code CLI..." -F Yellow
try {
    $installUri = "https://claude.ai/install.ps1"
    Write-Host "   从 $installUri 下载安装脚本..." -F Gray
    
    $installScript = irm $installUri -TimeoutSec 30 -ErrorAction Stop
    
    if ($installScript -and $installScript.Length -gt 100) {
        Write-Host "   安装脚本已下载，现在执行安装..." -F Gray
        Invoke-Expression $installScript
        Write-Host "✅ Claude Code 安装完成" -F Green
    }
    else {
        Write-Host "⚠️  Claude 安装脚本异常，请检查网络" -F Yellow
    }
}
catch {
    Write-Host "⚠️  Claude 安装失败: $_" -F Yellow
}

# 4. 自动修复 PATH
Write-Host "`n🔧 配置环境变量..." -F Yellow
try {
    $claudePath = Join-Path $env:USERPROFILE ".claude\local"
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($null -eq $userPath) {
        $userPath = ""
    }
    
    $pathItems = $userPath -split ";" | Where-Object { $_ -and $_.Trim() }
    $claudePathExists = $pathItems -contains $claudePath
    
    if (-not $claudePathExists) {
        $userPath = $userPath.TrimEnd(";")
        if ($userPath) {
            $newPath = "$userPath;$claudePath"
        }
        else {
            $newPath = $claudePath
        }
        
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "✅ 已添加 Claude 到用户环境变量" -F Green
    }
    else {
        Write-Host "✅ Claude 已在环境变量中" -F Green
    }
    
    $userPathEnv = [Environment]::GetEnvironmentVariable("PATH", "User")
    $machPathEnv = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    
    if ($null -eq $userPathEnv) { $userPathEnv = "" }
    if ($null -eq $machPathEnv) { $machPathEnv = "" }
    
    $env:PATH = if ($userPathEnv) { $userPathEnv + ";" } else { "" }
    $env:PATH += $machPathEnv
}
catch {
    Write-Host "❌ 环境变量配置失败: $_" -F Red
}

# 5. 弹窗输入 API Key
Write-Host "`n🔑 正在弹出 API Key 输入窗口..." -F Yellow
$apiKey = $null
$maxRetries = 3
$retry = 0

while ($retry -lt $maxRetries) {
    $apiKey = [Microsoft.VisualBasic.Interaction]::InputBox(
        "请输入 DeepSeek API Key（sk-开头）`n`n获取地址: https://platform.deepseek.com/api_keys",
        "DeepSeek API Key",
        "sk-"
    )
    
    if ($null -eq $apiKey -or $apiKey -eq "") {
        Write-Host "❌ 输入被取消或为空" -F Red
        pause
        exit 1
    }
    
    if ($apiKey -notlike "sk-*") {
        Write-Host "❌ 无效 API Key（必须以 'sk-' 开头）" -F Red
        $retry++
        if ($retry -lt $maxRetries) {
            Write-Host "   剩余尝试次数: $($maxRetries - $retry)" -F Yellow
        }
    }
    else {
        Write-Host "✅ API Key 格式正确" -F Green
        break
    }
}

if ($retry -eq $maxRetries) {
    Write-Host "`n❌ 超出重试次数，安装中止" -F Red
    pause
    exit 1
}

# 6. 写入配置（✅ 已修复 [1m] 括号解析错误）
Write-Host "`n📝 写入 PowerShell 配置..." -F Yellow
try {
    $profilePath = $PROFILE
    $profileDir = Split-Path -Parent $profilePath
    
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    
    # ✅ 这里是关键修复：deepseek-v4-pro`[1m`] 转义括号
    $cfg = @"
# Claude Code → DeepSeek V4 Pro[1m]
`$env:ANTHROPIC_BASE_URL = 'https://api.deepseek.com/anthropic'
`$env:ANTHROPIC_AUTH_TOKEN = '$apiKey'
`$env:ANTHROPIC_MODEL = 'deepseek-v4-pro`[1m`]'
`$env:API_TIMEOUT_MS = '600000'
`$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1'
"@
    
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType File -Force | Out-Null
    }
    
    Add-Content -Path $profilePath -Value "`n$cfg" -Encoding UTF8
    Write-Host "✅ 配置已写入: $profilePath" -F Green
}
catch {
    Write-Host "❌ 写入配置失败: $_" -F Red
}

# 完成
Write-Host "`n=============================================" -F Green
Write-Host "✅ 安装完成！" -F Green
Write-Host "=============================================" -F Green
Write-Host ""
Write-Host "📋 后续步骤:" -F Cyan
Write-Host "   1. 关闭并重新打开 PowerShell 终端" -F White
Write-Host "   2. 输入命令: claude" -F White
Write-Host "   3. 开始使用 Claude Code + DeepSeek!" -F White
Write-Host ""
pause
