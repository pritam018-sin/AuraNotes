@echo off
title AuraNotes Installer - AuraStudio Corporation
echo ==========================================================
echo        AuraNotes Installer (AuraStudio by Pritam)
echo ==========================================================
echo Installing AuraNotes to your system...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0install.ps1"
echo.
pause
