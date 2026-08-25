# Script: 365 Office app update (v1.0)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 213

# Run as admin

$officeApps = "winword","excel","outlook","powerpnt","onenote","msaccess","mspub","visio"
foreach ($app in $officeApps) {
    Get-Process $app -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

$cfgPath     = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
$updatesPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Updates"
$taskPath    = "\Microsoft\Office\Office Automatic Updates 2.0"
$c2rClient   = Join-Path $env:CommonProgramFiles "Microsoft Shared\ClickToRun\OfficeC2RClient.exe"

if (-not (Test-Path $cfgPath)) {
    Write-Host "Office Click-to-Run configuration not found."
    exit 1
}

$cfg = Get-ItemProperty -Path $cfgPath
$beforeVersion = $cfg.VersionToReport
if (-not $beforeVersion) { $beforeVersion = $cfg.ClientVersionToReport }

Write-Host "Current Office version: $beforeVersion"
Write-Host "UpdateChannel: $($cfg.UpdateChannel)"
Write-Host "CDNBaseUrl:   $($cfg.CDNBaseUrl)"
Write-Host "OfficeMgmtCOM: $($cfg.OfficeMgmtCOM)"

if ($cfg.OfficeMgmtCOM -eq $true -or $cfg.OfficeMgmtCOM -eq "True") {
    Write-Host "Office is ConfigMgr-managed. Updates may come only from Configuration Manager."
}

# Clear last detection time so Office checks again
if (Test-Path $updatesPath) {
    try {
        Set-ItemProperty -Path $updatesPath -Name UpdateDetectionLastRunTime -Value "" -ErrorAction SilentlyContinue
        Write-Host "Cleared UpdateDetectionLastRunTime"
    } catch {
        Write-Host "Could not clear UpdateDetectionLastRunTime"
    }
}

# Make sure scheduled task exists and is enabled
$task = Get-ScheduledTask -TaskPath "\Microsoft\Office\" -TaskName "Office Automatic Updates 2.0" -ErrorAction SilentlyContinue
if (-not $task) {
    Write-Host "Scheduled task 'Office Automatic Updates 2.0' not found."
    exit 1
}

if ($task.State -eq "Disabled") {
    Enable-ScheduledTask -TaskPath "\Microsoft\Office\" -TaskName "Office Automatic Updates 2.0"
    Write-Host "Enabled Office Automatic Updates 2.0"
}

# Optional nudge to Click-to-Run
if (Test-Path $c2rClient) {
    Write-Host "Triggering OfficeC2RClient..."
    Start-Process -FilePath $c2rClient -ArgumentList "/update user displaylevel=false forceappshutdown=true" -WindowStyle Hidden
}

# Primary trigger: scheduled task
Write-Host "Running Office Automatic Updates 2.0..."
Start-ScheduledTask -TaskPath "\Microsoft\Office\" -TaskName "Office Automatic Updates 2.0"

# Poll for up to 30 minutes
$timeoutMinutes = 30
$deadline = (Get-Date).AddMinutes($timeoutMinutes)
$changed = $false

do {
    Start-Sleep -Seconds 30
    $cfgNow = Get-ItemProperty -Path $cfgPath -ErrorAction SilentlyContinue
    $currentVersion = $cfgNow.VersionToReport
    if (-not $currentVersion) { $currentVersion = $cfgNow.ClientVersionToReport }

    Write-Host "Current detected version: $currentVersion"

    if ($currentVersion -and $currentVersion -ne $beforeVersion) {
        $changed = $true
        break
    }
}
while ((Get-Date) -lt $deadline)

if ($changed) {
    Write-Host "SUCCESS: Office updated from $beforeVersion to $currentVersion"
    exit 0
} else {
    Write-Host "No version change detected within $timeoutMinutes minutes."
    Write-Host "Check whether the device is managed by ConfigMgr/Intune/GPO or whether no newer build is available on the assigned channel."
    exit 2
}