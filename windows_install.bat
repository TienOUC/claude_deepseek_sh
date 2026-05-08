@echo off
chcp 65001 >nul
:: 同目录调用ps1，绕过PowerShell执行策略
powershell -ExecutionPolicy Bypass -File "%~dp0windows_install.ps1"
pause
