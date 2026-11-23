@echo off
title AuraNotes Uninstaller - AuraStudio Corporation
echo ==========================================================
echo        AuraNotes Uninstaller (AuraStudio by Pritam)
echo ==========================================================
echo Uninstalling AuraNotes from your system...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall.ps1"
echo.
pause
