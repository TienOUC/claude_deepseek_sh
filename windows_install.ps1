<#
Claude Code + DeepSeek V4 Pro[1m] 全自动安装
智能检测 Git/Node | 自动修复环境变量
#>

# Check PowerShell version (Issue #6 fix)
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "FAILED: This script requires PowerShell 5.0 or higher, current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}

Add-Type -AssemblyName Microsoft.VisualBasic
Clear-Host

$nodeMinVer = [version]"18.17.0"

Write-Host "=============================================" -F Cyan
Write-Host "  Claude Code Auto Install - DeepSeek Edition  " -F Cyan
Write-Host "=============================================" -F Cyan
Write-Host ""

# 0. Check execution policy
Write-Host "Checking PowerShell execution policy..." -F Yellow
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted") {
    Write-Host "WARNING: Current execution policy is Restricted, attempting to change..." -F Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "SUCCESS: Execution policy changed to RemoteSigned" -F Green
    }
    catch {
        Write-Host "ERROR: Unable to change execution policy, please run this script as administrator" -F Red
        pause
        exit 1
    }
}

# 1. Detect Git
Write-Host "`nDetecting Git..." -F Yellow
$gitInstalled = $false
try {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "SUCCESS: Git is already installed" -F Green
        $gitInstalled = $true
    }
    else {
        Write-Host "Installing Git..." -F Yellow
        $osVersion = [System.Environment]::OSVersion.Version
        
        if ($osVersion.Major -ge 10 -and $osVersion.Build -ge 22000) {
            try {
                winget install Git.Git -s winget --accept-source-agreements --accept-package-agreements -ErrorAction Stop
                Write-Host "SUCCESS: Git installed via winget" -F Green
                $gitInstalled = $true
            }
            catch {
                Write-Host "WARNING: winget installation failed: $_" -F Yellow
                Write-Host "   Please manually download from https://git-scm.com" -F Yellow
            }
        }
        else {
            Write-Host "WARNING: Windows version is too old, please install Git manually" -F Yellow
        }
    }
}
catch {
    Write-Host "ERROR: Git detection failed: $_" -F Red
}

# 2. Detect Node.js
Write-Host "`nDetecting Node.js (minimum version: $nodeMinVer)..." -F Yellow
$nodeInstalled = $false
try {
    $needInstall = $true
    
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $v = & node -v 2>$null
        if ($v -match 'v(\d+\.\d+\.\d+)') {
            $curr = [version]$matches[1]
            Write-Host "Current Node version: $curr" -F Cyan
            if ($curr -ge $nodeMinVer) {
                Write-Host "SUCCESS: Node version is compatible" -F Green
                $needInstall = $false
                $nodeInstalled = $true
            }
            else {
                Write-Host "WARNING: Node version is too old, update required..." -F Yellow
            }
        }
    }
    
    if ($needInstall) {
        Write-Host "Installing/updating Node.js LTS..." -F Yellow
        $osVersion = [System.Environment]::OSVersion.Version
        
        if ($osVersion.Major -ge 10 -and $osVersion.Build -ge 22000) {
            try {
                winget install OpenJS.NodeJS.LTS -s winget --accept-source-agreements --accept-package-agreements -ErrorAction Stop
                Write-Host "SUCCESS: Node.js installed via winget" -F Green
                $nodeInstalled = $true
            }
            catch {
                Write-Host "WARNING: winget installation failed: $_" -F Yellow
                Write-Host "   Please manually download from https://nodejs.org" -F Yellow
            }
        }
        else {
            Write-Host "WARNING: Please install Node.js LTS manually" -F Yellow
        }
    }
}
catch {
    Write-Host "ERROR: Node.js detection failed: $_" -F Red
}

function Update-SessionPathForClaude {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    $npmBin = Join-Path $env:APPDATA "npm"
    if ((Test-Path $npmBin) -and ($env:Path -notlike "*${npmBin}*")) {
        $env:Path = "$npmBin;$env:Path"
    }
}

function Test-ClaudeCommandAvailable {
    Update-SessionPathForClaude
    return $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
}

# 3. Install Claude CLI（官方脚本会请求 downloads.claude.ai，国内常被拒；失败则 winget / npm）
Write-Host "`nInstalling Claude Code CLI..." -F Yellow
$claudeReady = Test-ClaudeCommandAvailable

if ($claudeReady) {
    Write-Host "SUCCESS: claude 已在 PATH 中，跳过安装" -F Green
}
else {
    # 3a 官方在线脚本（内部仍会拉取 downloads.claude.ai）
    Write-Host "   [1/3] 尝试官方 install.ps1 ..." -F Gray
    try {
        $installUri = "https://claude.ai/install.ps1"
        $installScript = Invoke-RestMethod -Uri $installUri -TimeoutSec 60 -ErrorAction Stop
        if ($installScript -and $installScript.Length -gt 100) {
            Invoke-Expression $installScript
        }
    }
    catch {
        Write-Host "   官方脚本失败: $_" -F DarkYellow
    }
    Update-SessionPathForClaude
    $claudeReady = Test-ClaudeCommandAvailable

    # 3b winget（走微软源，不依赖 downloads.claude.ai）
    if (-not $claudeReady) {
        Write-Host "   [2/3] 尝试 winget 安装 Anthropic.ClaudeCode ..." -F Gray
        $wg = Get-Command winget -ErrorAction SilentlyContinue
        if ($wg) {
            try {
                $wingetArgs = @(
                    "install", "--id", "Anthropic.ClaudeCode", "-e",
                    "--accept-source-agreements", "--accept-package-agreements"
                )
                & winget @wingetArgs
                if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                    Write-Host "   winget 退出码: $LASTEXITCODE（若已安装过可能仍可忽略）" -F DarkYellow
                }
            }
            catch {
                Write-Host "   winget 失败: $_" -F DarkYellow
            }
        }
        else {
            Write-Host "   未找到 winget，跳过" -F DarkYellow
        }
        Update-SessionPathForClaude
        $claudeReady = Test-ClaudeCommandAvailable
    }

    # 3c npm 全局包（走 npm registry，可配国内镜像）
    if (-not $claudeReady) {
        Write-Host "   [3/3] 尝试 npm: @anthropic-ai/claude-code ..." -F Gray
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            try {
                & npm install -g @anthropic-ai/claude-code
            }
            catch {
                Write-Host "   npm 失败: $_" -F DarkYellow
            }
            Update-SessionPathForClaude
            $claudeReady = Test-ClaudeCommandAvailable
        }
        else {
            Write-Host "   未找到 npm，请先安装 Node.js 后再试" -F DarkYellow
        }
    }

    if ($claudeReady) {
        Write-Host "SUCCESS: 已检测到 claude 命令，CLI 安装成功" -F Green
    }
    else {
        Write-Host "FAILED: 未能安装或找不到 Claude Code CLI（claude 命令仍不可用）" -F Red
        Write-Host "   常见原因: 无法访问 downloads.claude.ai（防火墙/地区网络）" -F Yellow
        Write-Host "   可手动执行其一:" -F Yellow
        Write-Host "     winget install --id Anthropic.ClaudeCode -e" -F White
        Write-Host "     npm install -g @anthropic-ai/claude-code" -F White
        Write-Host "   配置好代理/VPN 后也可重新运行本脚本。" -F Yellow
    }
}

# 4. Auto-fix PATH
Write-Host "`nConfiguring environment variables..." -F Yellow
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
        Write-Host "SUCCESS: Added Claude to user environment variables" -F Green
    }
    else {
        Write-Host "SUCCESS: Claude is already in environment variables" -F Green
    }
    
    $userPathEnv = [Environment]::GetEnvironmentVariable("PATH", "User")
    $machPathEnv = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    
    if ($null -eq $userPathEnv) { $userPathEnv = "" }
    if ($null -eq $machPathEnv) { $machPathEnv = "" }
    
    $env:PATH = if ($userPathEnv) { $userPathEnv + ";" } else { "" }
    $env:PATH += $machPathEnv
}
catch {
    Write-Host "ERROR: Environment variable configuration failed: $_" -F Red
}

# 5. Input API Key dialog (FIXED v4)
Write-Host "`nOpening API Key input dialog..." -F Yellow
$apiKey = $null
$maxRetries = 3
$retry = 0
$apiKeyValid = $false

while ($retry -lt $maxRetries -and -not $apiKeyValid) {
    $apiKey = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Please enter DeepSeek API Key (starting with sk-)`n`nGet at: https://platform.deepseek.com/api_keys",
        "DeepSeek API Key",
        "sk-"
    )
    
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        $retry++
        Write-Host "ERROR: 已取消或为空，请重试（$retry / $maxRetries）" -F Red
        continue
    }
    
    if ($apiKey -notlike "sk-*") {
        Write-Host "ERROR: Invalid API Key (must start with 'sk-')" -F Red
        $retry++
        if ($retry -lt $maxRetries) {
            Write-Host "   Remaining attempts: $($maxRetries - $retry)" -F Yellow
        }
    }
    else {
        Write-Host "SUCCESS: API Key format is correct" -F Green
        $apiKeyValid = $true
    }
}

if (-not $apiKeyValid) {
    Write-Host "`nERROR: Maximum retries exceeded, installation aborted" -F Red
    pause
    exit 1
}

# 6. Write configuration (FIXED API Key injection, bracket escaping)
Write-Host "`nWriting PowerShell configuration..." -F Yellow
try {
    $profilePath = $PROFILE
    $profileDir = Split-Path -Parent $profilePath
    
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    
    # FIX: Using single quotes to prevent variable expansion, safe API Key escaping
    $cfg = @"
# Claude Code -> DeepSeek V4 Pro[1m]
`$env:ANTHROPIC_BASE_URL = 'https://api.deepseek.com/anthropic'
`$env:ANTHROPIC_AUTH_TOKEN = '$($apiKey -replace "'", "''")'
`$env:ANTHROPIC_MODEL = 'deepseek-v4-pro`[1m`]'
`$env:API_TIMEOUT_MS = '600000'
`$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1'
"@
    
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType File -Force | Out-Null
    }
    
    Add-Content -Path $profilePath -Value "`n$cfg" -Encoding UTF8
    Write-Host "SUCCESS: Configuration written to: $profilePath" -F Green
}
catch {
    Write-Host "ERROR: Configuration write failed: $_" -F Red
}

# Completion
Write-Host "`n=============================================" -F Cyan
if ($claudeReady) {
    Write-Host "SUCCESS: 安装与配置已完成！" -F Green
}
else {
    Write-Host "PARTIAL: DeepSeek 环境变量已写入，但本机未检测到 claude 命令" -F Yellow
    Write-Host "请先解决 CLI 安装（见上文 FAILED 提示），再重新打开终端运行 claude。" -F Yellow
}
Write-Host "=============================================" -F Cyan
Write-Host ""
Write-Host "后续步骤:" -F Cyan
Write-Host "   1. 关闭并重新打开 PowerShell" -F White
Write-Host "   2. 运行: claude" -F White
if (-not $claudeReady) {
    Write-Host "   （若提示找不到命令，请先执行 npm i -g @anthropic-ai/claude-code 或 winget 安装）" -F DarkYellow
}
Write-Host ""
pause
