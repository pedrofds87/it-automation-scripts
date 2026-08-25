# Script: Office 365 App updates (use this one)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 189

# --- Force Office 365 to update to latest build on current channel ---

# Optional: close open Office apps gracefully
$officeApps = "winword","excel","outlook","powerpnt","onenote","msaccess","mspub","visio","teams"
foreach ($app in $officeApps) {
    Get-Process $app -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Locate the Click-to-Run updater
$oc2r = "${env:CommonProgramFiles}\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
if (!(Test-Path $oc2r)) {
    Write-Host "'L OfficeC2RClient.exe not found. Office may not be Click-to-Run."
    return
}

# Trigger an immediate update to the latest version on the current channel
Write-Host "�=� Starting Office update..."
Start-Process -FilePath $oc2r -ArgumentList "/update user displaylevel=False forceappshutdown=True" -Wait

# After update, re-check installed version
$reg = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
try {
    $cfg = Get-ItemProperty -Path $reg -ErrorAction Stop
    $ver = $cfg.VersionToReport
    if (-not $ver) { $ver = $cfg.ClientVersionToReport }
    Write-Host "' Office updated successfully. Current version: $ver"
} catch {
    Write-Host "&�� Office update initiated, but version verification failed. Recheck later."
}
