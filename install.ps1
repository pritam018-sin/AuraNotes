# AuraNotes Professional Windows Installer
# Powered by AuraStudio Corporation • Pritam

$ErrorActionPreference = 'Stop'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         AuraNotes Desktop Installer" -ForegroundColor Green
Write-Host "       Powered by AuraStudio Corporation" -ForegroundColor Yellow
Write-Host "              Created by Pritam" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 0. Always locate the true release binaries in dist/AuraNotes-Windows-x64
$srcDir = $scriptDir
if (Test-Path "$scriptDir\dist\AuraNotes-Windows-x64\auranotes.exe") {
    $srcDir = "$scriptDir\dist\AuraNotes-Windows-x64"
} elseif (Test-Path "$scriptDir\build\windows\x64\runner\Release\auranotes.exe") {
    $srcDir = "$scriptDir\build\windows\x64\runner\Release"
} elseif (Test-Path "$scriptDir\auranotes.exe") {
    $srcDir = $scriptDir
} else {
    $parentDist = Join-Path (Split-Path -Parent $scriptDir) "dist\AuraNotes-Windows-x64"
    if (Test-Path "$parentDist\auranotes.exe") {
        $srcDir = $parentDist
    }
}

$installDir = Join-Path $env:LOCALAPPDATA "Programs\AuraNotes"
$exePath = Join-Path $installDir "auranotes.exe"
$iconPath = Join-Path $installDir "app_icon.ico"

Write-Host "Source directory: $srcDir" -ForegroundColor Cyan
Write-Host "Installing AuraNotes to: $installDir" -ForegroundColor White

# 1. Stop running instance if any
Get-Process -Name "AuraNotes","auranotes" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

# 2. Clean install directory to prevent mismatched old versions/source files
if (Test-Path $installDir) {
    Remove-Item -Path "$installDir\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# 3. Copy program files from dist
Copy-Item -Path "$srcDir\*" -Destination $installDir -Recurse -Force -Exclude "AuraNotes-Windows-Portable.zip"

# Ensure app_icon.ico exists
if (-not (Test-Path $iconPath)) {
    $rootIcon = Join-Path (Split-Path -Parent $srcDir) "app_icon.ico"
    if (Test-Path $rootIcon) {
        Copy-Item -Path $rootIcon -Destination $iconPath -Force
    }
}

# 4. Create Desktop Shortcuts (handle OneDrive Desktop and Local Desktop)
$wsh = New-Object -ComObject WScript.Shell
$desktopList = @()
$stdDesktop = [Environment]::GetFolderPath('Desktop')
if ($stdDesktop -and (Test-Path $stdDesktop)) { $desktopList += $stdDesktop }
$oneDriveDesktop = Join-Path $env:USERPROFILE "OneDrive\Desktop"
if (Test-Path $oneDriveDesktop) { $desktopList += $oneDriveDesktop }

foreach ($dt in ($desktopList | Select-Object -Unique)) {
    $desktopShortcut = Join-Path $dt "AuraNotes.lnk"
    $scDesktop = $wsh.CreateShortcut($desktopShortcut)
    $scDesktop.TargetPath = $exePath
    $scDesktop.WorkingDirectory = $installDir
    $scDesktop.Description = "AuraNotes - Modern Notion-grade Desktop Workspace (AuraStudio)"
    if (Test-Path $iconPath) {
        $scDesktop.IconLocation = "$iconPath,0"
    }
    $scDesktop.Save()
    Write-Host "[OK] Desktop shortcut created at $dt" -ForegroundColor Green
}

# 5. Create Start Menu Shortcut
$startMenuDir = [Environment]::GetFolderPath('Programs')
$startMenuShortcut = Join-Path $startMenuDir "AuraNotes.lnk"
$scStart = $wsh.CreateShortcut($startMenuShortcut)
$scStart.TargetPath = $exePath
$scStart.WorkingDirectory = $installDir
$scStart.Description = "AuraNotes - Modern Notion-grade Desktop Workspace (AuraStudio)"
if (Test-Path $iconPath) {
    $scStart.IconLocation = "$iconPath,0"
}
$scStart.Save()
Write-Host "[OK] Start Menu shortcut created" -ForegroundColor Green

# 5. Register in Windows Add or Remove Programs (Control Panel & Windows Settings)
$uninstallRegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\AuraNotes"
New-Item -Path $uninstallRegKey -Force | Out-Null
Set-ItemProperty -Path $uninstallRegKey -Name "DisplayName" -Value "AuraNotes"
Set-ItemProperty -Path $uninstallRegKey -Name "DisplayVersion" -Value "1.0.0"
Set-ItemProperty -Path $uninstallRegKey -Name "Publisher" -Value "AuraStudio Corporation (Pritam)"
Set-ItemProperty -Path $uninstallRegKey -Name "DisplayIcon" -Value "$iconPath,0"
Set-ItemProperty -Path $uninstallRegKey -Name "InstallLocation" -Value $installDir
Set-ItemProperty -Path $uninstallRegKey -Name "UninstallString" -Value "`"$installDir\Uninstall-AuraNotes.bat`""
Set-ItemProperty -Path $uninstallRegKey -Name "URLInfoAbout" -Value "https://github.com/pritam018-sin/AuraNotes"
Set-ItemProperty -Path $uninstallRegKey -Name "HelpLink" -Value "https://github.com/pritam018-sin/AuraNotes"
Set-ItemProperty -Path $uninstallRegKey -Name "NoModify" -Value 1 -Type DWord
Set-ItemProperty -Path $uninstallRegKey -Name "NoRepair" -Value 1 -Type DWord
Write-Host "[OK] Registered in Windows Settings (Apps & Features)" -ForegroundColor Green

# 6. Register Markdown & Note File Associations & Right-Click Context Menu
$noteExtensions = @('.md', '.markdown', '.note', '.auranote')

# App Paths
$appPathsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\AuraNotes.exe"
New-Item -Path $appPathsKey -Force | Out-Null
Set-ItemProperty -Path $appPathsKey -Name "(Default)" -Value $exePath
Set-ItemProperty -Path $appPathsKey -Name "Path" -Value $installDir

# ProgID
$progIdKey = "HKCU:\Software\Classes\AuraNotes.Document"
New-Item -Path $progIdKey -Force | Out-Null
Set-ItemProperty -Path $progIdKey -Name "(Default)" -Value "AuraNotes Markdown Document"
Set-ItemProperty -Path $progIdKey -Name "FriendlyTypeName" -Value "AuraNotes Markdown Document"

$progIdIconKey = "$progIdKey\DefaultIcon"
New-Item -Path $progIdIconKey -Force | Out-Null
Set-ItemProperty -Path $progIdIconKey -Name "(Default)" -Value "$iconPath,0"

$progIdOpenKey = "$progIdKey\shell\open\command"
New-Item -Path $progIdOpenKey -Force | Out-Null
Set-ItemProperty -Path $progIdOpenKey -Name "(Default)" -Value "`"$exePath`" `"%1`""

# Applications
$appKey = "HKCU:\Software\Classes\Applications\AuraNotes.exe"
New-Item -Path $appKey -Force | Out-Null
Set-ItemProperty -Path $appKey -Name "FriendlyAppName" -Value "AuraNotes"

$appOpenKey = "$appKey\shell\open\command"
New-Item -Path $appOpenKey -Force | Out-Null
Set-ItemProperty -Path $appOpenKey -Name "(Default)" -Value "`"$exePath`" `"%1`""

$appSupportedTypes = "$appKey\SupportedTypes"
New-Item -Path $appSupportedTypes -Force | Out-Null
foreach ($ext in $noteExtensions) {
    Set-ItemProperty -Path $appSupportedTypes -Name $ext -Value ""
}

# Context Menu: "Edit in AuraNotes"
foreach ($ext in $noteExtensions) {
    $extAssocKey = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\AuraNotes"
    New-Item -Path $extAssocKey -Force | Out-Null
    Set-ItemProperty -Path $extAssocKey -Name "(Default)" -Value "Edit in AuraNotes"
    Set-ItemProperty -Path $extAssocKey -Name "Icon" -Value "$iconPath,0"

    $extCommandKey = "$extAssocKey\command"
    New-Item -Path $extCommandKey -Force | Out-Null
    Set-ItemProperty -Path $extCommandKey -Name "(Default)" -Value "`"$exePath`" `"%1`""
}
Write-Host "[OK] Document context menu & Open With options registered" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   INSTALLATION COMPLETE: AuraNotes is ready to use!" -ForegroundColor Green
Write-Host "   Launch from Desktop Shortcut or Start Menu." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
