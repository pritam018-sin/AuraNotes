$ErrorActionPreference = 'Stop'

$projectRoot = 'C:\Users\DELL\WebDevPractice\chrome\AuraNotes'
$releaseDir = "$projectRoot\build\windows\x64\runner\Release"
$distDir = "$projectRoot\dist"
$portableFolder = "$distDir\AuraNotes-Windows-x64"
$zipPath = "$distDir\AuraNotes-Windows-Portable.zip"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Creating AuraNotes Portable & Shareable Release Bundle" -ForegroundColor Green
Write-Host "   Powered by AuraStudio Corporation • Pritam" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# Stop running instance if any
Get-Process -Name "AuraNotes","auranotes" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

# Ensure release exists
if (-not (Test-Path $releaseDir)) {
    Write-Error "Release directory not found: $releaseDir"
    exit 1
}

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

if (Test-Path $portableFolder) {
    Remove-Item -Path $portableFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $portableFolder -Force | Out-Null

# Copy all runtime files into portable folder
Copy-Item -Path "$releaseDir\*" -Destination $portableFolder -Recurse -Force -Exclude "*.exp","*.lib"

# Copy installer and uninstaller scripts
Copy-Item -Path "$projectRoot\Install-AuraNotes.bat" -Destination $portableFolder -Force
Copy-Item -Path "$projectRoot\Uninstall-AuraNotes.bat" -Destination $portableFolder -Force
Copy-Item -Path "$projectRoot\install.ps1" -Destination $portableFolder -Force
Copy-Item -Path "$projectRoot\uninstall.ps1" -Destination $portableFolder -Force
Copy-Item -Path "$projectRoot\app_icon.ico" -Destination $portableFolder -Force

# Add README.txt
$readme = @"
====================================================================
                  AuraNotes - Windows Suite
        Powered by AuraStudio Corporation • Pritam
====================================================================
A modern AppFlowy-styled desktop knowledge workspace with Notion-grade power.

HOW TO USE / INSTALL:
- OPTION A (Portable): Double-click 'AuraNotes.exe' to run directly with zero installation!
- OPTION B (Full Install): Double-click 'Install-AuraNotes.bat' to:
    1. Install to your Windows user programs folder.
    2. Add Desktop & Start Menu shortcuts with custom glowing icon.
    3. Register "Edit in AuraNotes" on all Markdown & Note files.
    4. Register official Windows Add or Remove Programs uninstaller.
- TO UNINSTALL: Double-click 'Uninstall-AuraNotes.bat' at any time.

DEVELOPER & CORPORATION:
- Organization: AuraStudio Corporation
- Created by: Pritam
- Engine: AppFlowy Core Architecture & Flutter Native D3D11 C++ Runner
- License: MIT License

FEATURES:
  • Multi-View Studio: Document Editor, Kanban Board, Database Grid, AI Studio
  • Slash Commands: Type / on any line to insert blocks
  • Command Palette: Press Ctrl + K to instantly search anything
  • Offline & Private: 100% local-first data storage with zero tracking
"@

Set-Content -Path "$portableFolder\README.txt" -Value $readme -Encoding UTF8

Write-Host "Creating zip archive for sharing with friend..." -ForegroundColor Yellow
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}
Compress-Archive -Path "$portableFolder\*" -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   PACKAGING COMPLETE!" -ForegroundColor Green
Write-Host "   Portable Folder: $portableFolder" -ForegroundColor White
Write-Host "   Shareable Zip:   $zipPath" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
