# Script: Chrome update (use this one)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 180

# Enable Continue where you left off + Update Chrome (Windows)
$ErrorActionPreference = 'SilentlyContinue'

# Find Chrome user profile
$userProfile = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Preferences"
if (Test-Path $userProfile) {
    Write-Host "Enabling 'Continue where you left off'..."
    $json = Get-Content $userProfile -Raw | ConvertFrom-Json
    if (-not $json.session) { $json | Add-Member -MemberType NoteProperty -Name session -Value @{} }
    $json.session.restore_on_startup = 1
    $json.session.startup_urls = @()
    $json | ConvertTo-Json -Depth 100 | Set-Content $userProfile -Encoding UTF8
} else {
    Write-Warning "Preferences file not found. Skipping session setting."
}

# Show current Chrome version
$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) {
    $chromeExe = "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chromeExe)) {
    Write-Error "Chrome not found."; exit 1
}
$before = (Get-Item $chromeExe).VersionInfo.ProductVersion
Write-Host "Current Chrome version: $before"

# Close Chrome gracefully
Write-Host "Closing Chrome..."
Get-Process chrome -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.CloseMainWindow() | Out-Null } catch {}
}
Start-Sleep -Seconds 3
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

# Download latest installer
$installer = Join-Path $env:TEMP "chrome_installer.exe"
$downloadUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
Write-Host "Downloading latest Chrome..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $installer -UseBasicParsing

# Install silently (needs admin for system installs)
Write-Host "Installing Chrome update..."
Start-Process $installer -ArgumentList "/silent","/install" -Wait
Remove-Item $installer -Force -ErrorAction SilentlyContinue

# Relaunch Chrome
Write-Host "Reopening Chrome..."
Start-Process $chromeExe

Start-Sleep -Seconds 3
$after = (Get-Item $chromeExe).VersionInfo.ProductVersion
Write-Host "Updated Chrome version: $after"
