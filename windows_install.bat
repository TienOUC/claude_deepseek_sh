@echo off
setlocal
cd /d "%~dp0"
REM Launcher must stay ASCII-only: CMD uses system code page and breaks UTF-8.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows_install.ps1"
set ERR=%ERRORLEVEL%
pause
exit /b %ERR%
