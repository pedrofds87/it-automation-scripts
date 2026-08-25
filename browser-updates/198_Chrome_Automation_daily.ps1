# Script: Chrome Automation daily
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 198

# Enable Continue where you left off + Update Chrome (Windows) - only if update is needed
$ErrorActionPreference = 'SilentlyContinue'

function Get-InstalledChromeExe {
    $candidates = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
    return $null
}

function Get-LatestChromeStableVersionWin {
    # "Chrome for Testing" JSON (Google-maintained)
    $uri = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
    $json = Invoke-RestMethod -Uri $uri -Method Get
    return $json.channels.Stable.version
}

function Get-LatestChromeStableInstallerWinUrl {
    $uri = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
    $json = Invoke-RestMethod -Uri $uri -Method Get

    # pick the stable Windows installer (exe) if present; otherwise fall back to the first win64 URL
    $downloads = $json.channels.Stable.downloads.chrome
    $win = $downloads | Where-Object { $_.platform -in @("win64","win32") }

    $exe = $win | Where-Object { $_.url -match '\.exe($|\?)' } | Select-Object -First 1
    if ($exe) { return $exe.url }

    # fallback (some entries are zips); still return something useful
    return ($win | Select-Object -First 1).url
}

# --- Locate Chrome and read installed version ---
$chromeExe = Get-InstalledChromeExe
if (-not $chromeExe) { Write-Error "Chrome not found."; exit 1 }

$installedVersion = (Get-Item $chromeExe).VersionInfo.ProductVersion
Write-Host "Installed Chrome version: $installedVersion"

# --- Check latest stable version ---
$latestVersion = Get-LatestChromeStableVersionWin
Write-Host "Latest Stable (Windows) version: $latestVersion"

$installed = [version]($installedVersion -replace '[^\d\.].*$','')
$latest    = [version]($latestVersion)

if ($installed -ge $latest) {
    Write-Host "Chrome is up to date. Skipping update + profile changes."
    exit 0
}

Write-Host "Update needed. Proceeding..."

# --- Update 'Continue where you left off' (only when updating) ---
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

# --- Close Chrome gracefully ---
Write-Host "Closing Chrome..."
Get-Process chrome -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.CloseMainWindow() | Out-Null } catch {}
}
Start-Sleep -Seconds 3
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

# --- Download + install ---
$installer = Join-Path $env:TEMP "chrome_installer.exe"
$downloadUrl = Get-LatestChromeStableInstallerWinUrl
Write-Host "Downloading Chrome from: $downloadUrl"
Invoke-WebRequest -Uri $downloadUrl -OutFile $installer -UseBasicParsing

Write-Host "Installing Chrome update..."
Start-Process $installer -ArgumentList "/silent","/install" -Wait
Remove-Item $installer -Force -ErrorAction SilentlyContinue

# --- Relaunch + report ---
Write-Host "Reopening Chrome..."
Start-Process $chromeExe

Start-Sleep -Seconds 3
$after = (Get-Item $chromeExe).VersionInfo.ProductVersion
Write-Host "Updated Chrome version: $after"
