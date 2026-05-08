<#
Claude Code + DeepSeek V4 Pro[1m] 全自动安装
强制 PowerShell 运行 | 智能检测 Git/Node | 自动修复环境变量
最终修复版 v4: 修复 API Key 输入循环、环境变量注入、执行策略
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

# 3. Install Claude CLI
Write-Host "`nInstalling Claude Code CLI..." -F Yellow
try {
    $installUri = "https://claude.ai/install.ps1"
    Write-Host "   Downloading installation script from $installUri..." -F Gray
    
    $installScript = irm $installUri -TimeoutSec 30 -ErrorAction Stop
    
    if ($installScript -and $installScript.Length -gt 100) {
        Write-Host "   Installation script downloaded, executing now..." -F Gray
        Invoke-Expression $installScript
        Write-Host "SUCCESS: Claude Code installation completed" -F Green
    }
    else {
        Write-Host "WARNING: Claude installation script is abnormal, please check network" -F Yellow
    }
}
catch {
    Write-Host "WARNING: Claude installation failed: $_" -F Yellow
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
    
    if ($null -eq $apiKey -or $apiKey -eq "") {
        Write-Host "ERROR: Input cancelled or empty" -F Red
        pause
        exit 1
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
Write-Host "`n=============================================" -F Green
Write-Host "SUCCESS: Installation completed!" -F Green
Write-Host "=============================================" -F Green
Write-Host ""
Write-Host "Next Steps:" -F Cyan
Write-Host "   1. Close and reopen PowerShell terminal" -F White
Write-Host "   2. Run command: claude" -F White
Write-Host "   3. Start using Claude Code + DeepSeek!" -F White
Write-Host ""
pause
