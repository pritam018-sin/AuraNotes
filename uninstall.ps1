# AuraNotes Professional Windows Uninstaller
# Powered by AuraStudio Corporation • Pritam

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         AuraNotes Desktop Uninstaller" -ForegroundColor Red
Write-Host "       Powered by AuraStudio Corporation" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Removing AuraNotes from your system..." -ForegroundColor White

# 1. Stop running instance
Get-Process -Name "AuraNotes","auranotes" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

$installDir = Join-Path $env:LOCALAPPDATA "Programs\AuraNotes"

# 2. Remove Shortcuts
$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "AuraNotes.lnk"
if (Test-Path $desktopShortcut) {
    Remove-Item -Path $desktopShortcut -Force
}

$startMenuShortcut = Join-Path ([Environment]::GetFolderPath('Programs')) "AuraNotes.lnk"
if (Test-Path $startMenuShortcut) {
    Remove-Item -Path $startMenuShortcut -Force
}

# 3. Remove Registry Entries
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\AuraNotes" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\AuraNotes.exe" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\AuraNotes.Document" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\Applications\AuraNotes.exe" -Recurse -Force

$noteExtensions = @('.md', '.markdown', '.note', '.auranote')
foreach ($ext in $noteExtensions) {
    Remove-Item -Path "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\AuraNotes" -Recurse -Force
    Remove-Item -Path "HKCU:\Software\Classes\$ext\OpenWithList\AuraNotes.exe" -Recurse -Force
    Remove-ItemProperty -Path "HKCU:\Software\Classes\$ext\OpenWithProgids" -Name "AuraNotes.Document" -Force
}

# 4. Remove Program Files directory (scheduled if self-running)
if (Test-Path $installDir) {
    # Remove files
    Get-ChildItem -Path $installDir -Exclude "Uninstall-AuraNotes.bat","uninstall.ps1" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    # Schedule self-deletion of remaining directory
    Start-Process -WindowStyle Hidden -FilePath cmd.exe -ArgumentList "/c timeout /t 2 /nobreak & rd /s /q `"$installDir`""
}

Write-Host "SUCCESS: AuraNotes has been completely and cleanly uninstalled." -ForegroundColor Green
