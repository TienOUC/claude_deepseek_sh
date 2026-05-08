@echo off
title 正在启动 PowerShell 安装...
mode con cols=80 lines=10
cd /d "%~dp0"

:: 强制用 PowerShell 运行（不会进入 cmd）
powershell.exe -NoLogo -ExecutionPolicy Bypass -File "%~dp0windows_install.ps1"

pause
exit
