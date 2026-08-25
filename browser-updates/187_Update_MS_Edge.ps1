# Script: Update MS Edge
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 187

# Edge update & session restore helper (no winget)

$ErrorActionPreference = 'SilentlyContinue'

# --- Locate Edge executable ---
$edgeExe = @(
  "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $edgeExe) {
    Write-Host "[ERROR] Microsoft Edge not found." -ForegroundColor Red
    exit 1
}

# --- Enable  Continue where you left off  ---
$prefPath = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Preferences"
if (Test-Path $prefPath) {
    try {
        $prefs = Get-Content $prefPath -Raw | ConvertFrom-Json
        if (-not $prefs.session) { $prefs | Add-Member -MemberType NoteProperty -Name session -Value @{} }
        $prefs.session.restore_on_startup = 1
        $prefs.session.startup_urls = @()
        $prefs | ConvertTo-Json -Depth 100 | Set-Content $prefPath -Encoding UTF8
        Write-Host "[OK] Enabled 'Continue where you left off'."
    } catch {
        Write-Warning "Could not edit Preferences (Edge may be running)."
    }
} else {
    Write-Warning "Preferences file not found (user has not launched Edge yet)."
}

# --- Show current version ---
$before = (Get-Item $edgeExe).VersionInfo.ProductVersion
Write-Host "[INFO] Edge version before update: $before"

# --- Close Edge gracefully ---
Write-Host "[INFO] Closing Edge..."
Get-Process msedge -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.CloseMainWindow() | Out-Null } catch {}
}
Start-Sleep -Seconds 3
Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force

# --- Run MicrosoftEdgeUpdate manually ---
$edgeUpdateExe = "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
if (Test-Path $edgeUpdateExe) {
    Write-Host "[INFO] Running MicrosoftEdgeUpdate..."
    Start-Process $edgeUpdateExe -ArgumentList "/ua /installsource scheduler" -Wait
} else {
    Write-Warning "Edge Update executable not found. Attempting direct installer download..."
    $installer = Join-Path $env:TEMP "MicrosoftEdgeSetup.exe"
    Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2109047" -OutFile $installer -UseBasicParsing
    Start-Process $installer -ArgumentList "/silent /install" -Wait
    Remove-Item $installer -Force -ErrorAction SilentlyContinue
}

# --- Relaunch Edge ---
Write-Host "[INFO] Reopening Microsoft Edge..."
Start-Process $edgeExe
Start-Sleep -Seconds 3

# --- Show updated version ---
$after = (Get-Item $edgeExe).VersionInfo.ProductVersion
Write-Host "[INFO] Edge version after update: $after"
Write-Host "' Done. Tabs will restore automatically."
