# Script: Update MS Edge (using winget)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 186

# Edge: enable "Continue where you left off", update, and relaunch

$ErrorActionPreference = 'SilentlyContinue'

# --- Locate Edge executable ---
$edgeExe = @(
  "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $edgeExe) { Write-Error "Microsoft Edge not found."; exit 1 }

# --- Enable 'Continue where you left off' in Default profile ---
$prefPath = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Preferences"
if (Test-Path $prefPath) {
    try {
        $json = Get-Content $prefPath -Raw | ConvertFrom-Json
        if (-not $json.session) { $json | Add-Member -MemberType NoteProperty -Name session -Value @{} }
        $json.session.restore_on_startup = 1     # 1 = restore last session
        $json.session.startup_urls = @()         # ensure no fixed URL list
        $json | ConvertTo-Json -Depth 100 | Set-Content $prefPath -Encoding UTF8
        Write-Host "[OK] Enabled 'Continue where you left off'."
    } catch { Write-Warning "Could not modify Preferences (is Edge running?)." }
} else {
    Write-Warning "Preferences file not found (no Default profile yet?)."
}

# --- Version before ---
$before = (Get-Item $edgeExe).VersionInfo.ProductVersion
Write-Host "[INFO] Edge version (before): $before"

# --- Close Edge gracefully, then force if needed ---
Write-Host "[INFO] Closing Edge..."
Get-Process msedge -ErrorAction SilentlyContinue | ForEach-Object { try { $_.CloseMainWindow() | Out-Null } catch {} }
Start-Sleep -Seconds 3
Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force

# --- Try to update via winget (preferred) ---
$updated = $false
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "[INFO] Updating Edge via winget..."
    try {
        winget upgrade --id Microsoft.Edge -e --silent --accept-package-agreements --accept-source-agreements
        $updated = $true
    } catch { Write-Warning "winget update attempt failed." }
} else {
    Write-Warning "winget not available."
}

# --- Fallback: Microsoft Edge Update (Omaha) if present ---
if (-not $updated) {
    $edgeUpdate = "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
    if (Test-Path $edgeUpdate) {
        Write-Host "[INFO] Forcing EdgeUpdate to check/apply updates..."
        # Generic update trigger (no GUID needed in most cases)
        Start-Process $edgeUpdate -ArgumentList "/ua /installsource scheduler" -Wait
        $updated = $true
    } else {
        Write-Warning "EdgeUpdate not found; skipping fallback."
    }
}

# --- Relaunch Edge ---
Write-Host "[INFO] Reopening Edge..."
Start-Process $edgeExe

Start-Sleep -Seconds 3
$after = (Get-Item $edgeExe).VersionInfo.ProductVersion
Write-Host "[INFO] Edge version (after):  $after"
