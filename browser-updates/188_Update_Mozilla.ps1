# Script: Update Mozilla
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 188

# Firefox update & session-restore helper (no winget)

$ErrorActionPreference = 'SilentlyContinue'

# --- Locate Firefox executable (system or user) ---
$ffExe = @(
  "C:\Program Files\Mozilla Firefox\firefox.exe",
  "C:\Program Files (x86)\Mozilla Firefox\firefox.exe",
  "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $ffExe) {
    Write-Host "[ERROR] Firefox not found." -ForegroundColor Red
    exit 1
}

# --- Version before ---
$before = (Get-Item $ffExe).VersionInfo.ProductVersion
Write-Host "[INFO] Firefox version before update: $before"

# --- Enable  Restore previous session  for the default profile ---
# Find default profile from profiles.ini
$profilesIni = Join-Path $env:APPDATA "Mozilla\Firefox\profiles.ini"
if (Test-Path $profilesIni) {
    $lines = Get-Content $profilesIni
    $current = @{}
    $defaultProfilePath = $null
    foreach ($line in $lines) {
        if ($line -match '^\[Profile') { $current = @{}; continue }
        if ($line -match '^Path=(.*)$')        { $current.Path = $Matches[1] }
        elseif ($line -match '^IsRelative=(\d)'){ $current.IsRel = $Matches[1] }
        elseif ($line -match '^Default=(\d)')   { $current.IsDefault = $Matches[1] }
        if ($current.Path -and $current.IsRel -and $current.IsDefault -eq '1') {
            if ($current.IsRel -eq '1') {
                $defaultProfilePath = Join-Path (Split-Path $profilesIni -Parent) $current.Path
            } else {
                $defaultProfilePath = $current.Path
            }
            break
        }
    }

    if ($defaultProfilePath -and (Test-Path $defaultProfilePath)) {
        $userJs = Join-Path $defaultProfilePath "user.js"
        # Ensure the file exists; then set the prefs
        if (-not (Test-Path $userJs)) { New-Item -Path $userJs -ItemType File -Force | Out-Null }

        # Remove existing lines for these prefs, then append desired values
        $existing = Get-Content $userJs -Raw
        $filtered = $existing -replace 'user_pref\("browser\.startup\.page".*?\);\s*','' `
                              -replace 'user_pref\("browser\.sessionstore\.resume_from_crash".*?\);\s*',''
        $desired = @(
            'user_pref("browser.startup.page", 3);',                 # 3 = "Restore previous session"
            'user_pref("browser.sessionstore.resume_from_crash", true);'
        ) -join "`r`n"
        ($filtered.Trim() + "`r`n" + $desired + "`r`n") | Set-Content $userJs -Encoding UTF8

        Write-Host "[OK] Enabled 'Restore previous session' in profile: $defaultProfilePath"
    } else {
        Write-Warning "Default Firefox profile not found (has the user launched Firefox yet?)."
    }
} else {
    Write-Warning "profiles.ini not found; cannot set session preference."
}

# --- Close Firefox gracefully ---
Write-Host "[INFO] Closing Firefox..."
Get-Process firefox -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.CloseMainWindow() | Out-Null } catch {}
}
Start-Sleep -Seconds 3
Get-Process firefox -ErrorAction SilentlyContinue | Stop-Process -Force

# --- Decide installer (32-bit vs 64-bit) ---
$os64 = [Environment]::Is64BitOperatingSystem
$exePathLower = $ffExe.ToLowerInvariant()
$ffIs32 = $exePathLower -like "*program files (x86)*"
# Use 64-bit unless the installed Firefox is clearly 32-bit
if ($os64 -and -not $ffIs32) {
    $downloadUrl = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
} else {
    $downloadUrl = "https://download.mozilla.org/?product=firefox-latest&os=win&lang=en-US"
}

# --- Download & silent install (official) ---
$installer = Join-Path $env:TEMP "FirefoxSetup.exe"
try {
    Write-Host "[INFO] Downloading latest Firefox installer..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installer -UseBasicParsing
    Write-Host "[INFO] Running silent installer..."
    # /S = silent; installer will update in place (may need admin if system-wide install)
    Start-Process $installer -ArgumentList "/S" -Wait
} catch {
    Write-Host "[ERROR] Download or install failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item $installer -Force -ErrorAction SilentlyContinue
}

# --- Reopen Firefox ---
Write-Host "[INFO] Reopening Firefox..."
Start-Process $ffExe
Start-Sleep -Seconds 2

# --- Version after ---
$after = (Get-Item $ffExe).VersionInfo.ProductVersion
Write-Host "[INFO] Firefox version after update: $after"
Write-Host "' Done. Session will restore automatically."
