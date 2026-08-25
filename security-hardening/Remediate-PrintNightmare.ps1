#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Remediation script for CVE-2021-34527 (PrintNightmare) - Point and Print registry hardening.

.DESCRIPTION
    Addresses the insecure Point and Print registry configuration identified by Tenable
    under HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint.

    Actions performed:
      1. Backs up current registry state to a timestamped log file.
      2. Sets NoWarningNoElevationOnInstall = 0 (eliminates silent driver installs).
      3. Sets UpdatePromptSettings = 0 (restores elevation prompts on driver updates).
      4. Optionally restricts/disables the Print Spooler service on non-print servers.
      5. Logs all changes with before/after values.

.PARAMETER DisableSpooler
    If specified, stops and disables the Print Spooler service entirely.
    Use this only on servers/workstations that do not need printing.

.PARAMETER RestrictSpoolerToLocal
    If specified, configures the spooler to accept local connections only
    (blocks remote print exploitation while preserving local printing).

.PARAMETER LogPath
    Path for the remediation log. Defaults to C:\Logs\PrintNightmare-Remediation.

.PARAMETER WhatIf
    Runs in read-only audit mode. Reports current state without making changes.

.EXAMPLE
    # Audit only - no changes
    .\Remediate-PrintNightmare.ps1 -WhatIf

    # Registry fix only (safest for print servers)
    .\Remediate-PrintNightmare.ps1

    # Registry fix + restrict spooler to local connections
    .\Remediate-PrintNightmare.ps1 -RestrictSpoolerToLocal

    # Full lockdown - disable spooler entirely (non-print machines)
    .\Remediate-PrintNightmare.ps1 -DisableSpooler

.NOTES
    CVE:        CVE-2021-34527
    Reference:  https://support.microsoft.com/kb/5005010
    Tested on:  Windows 10, Windows Server 2016/2019/2022
    Author:     IT Operations
    Version:    1.2
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$DisableSpooler,
    [switch]$RestrictSpoolerToLocal,
    [string]$LogPath = "C:\Logs\PrintNightmare-Remediation"
)

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
$RegBase  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
$LogFile  = Join-Path $LogPath ("Remediation_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$Hostname = $env:COMPUTERNAME

$TargetValues = @{
    NoWarningNoElevationOnInstall = 0   # MUST be 0; value of 1 is the vulnerability
    UpdatePromptSettings          = 0   # MUST be 0; value of 2 suppresses prompts (vulnerable)
}

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line -ForegroundColor $(
        switch ($Level) {
            "WARN"    { "Yellow" }
            "ERROR"   { "Red"    }
            "SUCCESS" { "Green"  }
            default   { "Cyan"   }
        }
    )
    if (-not $WhatIfPreference) {
        Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
    }
}

function Initialize-Log {
    if (-not $WhatIfPreference) {
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
        Write-Log "=== PrintNightmare Remediation Log ==="
        Write-Log "Host     : $Hostname"
        Write-Log "OS       : $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Log "Mode     : $(if ($WhatIfPreference) { 'AUDIT (no changes)' } else { 'REMEDIATION' })"
        Write-Log "========================================="
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — AUDIT CURRENT STATE
# ─────────────────────────────────────────────────────────────────────────────
function Get-CurrentState {
    Write-Log "--- Auditing current registry state ---"

    $state = @{}
    foreach ($valueName in $TargetValues.Keys) {
        $current = $null
        try {
            $current = Get-ItemPropertyValue -Path $RegBase -Name $valueName -ErrorAction Stop
        } catch {
            $current = "NOT SET"
        }
        $state[$valueName] = $current

        $safe    = ($current -eq 0) -or ($current -eq "NOT SET")
        $status  = if ($safe) { "OK" } else { "VULNERABLE" }
        $color   = if ($safe) { "SUCCESS" } else { "WARN" }
        Write-Log ("  {0,-45} = {1,-10} [{2}]" -f $valueName, $current, $status) $color
    }

    # Also check if the key exists at all
    if (-not (Test-Path $RegBase)) {
        Write-Log "  Registry key does not exist — system is not vulnerable via this path." "SUCCESS"
    }

    return $state
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — APPLY REGISTRY FIX
# ─────────────────────────────────────────────────────────────────────────────
function Set-RegistryRemediation {
    param([hashtable]$Before)

    Write-Log "--- Applying registry remediation ---"

    # Ensure the key exists
    if (-not (Test-Path $RegBase)) {
        if ($PSCmdlet.ShouldProcess($RegBase, "Create registry key")) {
            New-Item -Path $RegBase -Force | Out-Null
            Write-Log "  Created registry key: $RegBase"
        }
    }

    foreach ($entry in $TargetValues.GetEnumerator()) {
        $valueName = $entry.Key
        $desired   = $entry.Value
        $current   = $Before[$valueName]

        if ($current -eq $desired) {
            Write-Log ("  {0} already set to {1} — no change needed." -f $valueName, $desired) "SUCCESS"
            continue
        }

        if ($PSCmdlet.ShouldProcess("$RegBase\$valueName", "Set DWORD value to $desired (was: $current)")) {
            Set-ItemProperty -Path $RegBase -Name $valueName -Value $desired -Type DWord -Force
            Write-Log ("  SET {0}: {1} → {2}" -f $valueName, $current, $desired) "SUCCESS"
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — VERIFY
# ─────────────────────────────────────────────────────────────────────────────
function Confirm-Remediation {
    Write-Log "--- Verifying post-remediation state ---"
    $allClean = $true

    foreach ($valueName in $TargetValues.Keys) {
        $actual = $null
        try {
            $actual = Get-ItemPropertyValue -Path $RegBase -Name $valueName -ErrorAction Stop
        } catch {
            $actual = "NOT SET"
        }

        $desired = $TargetValues[$valueName]
        $clean   = ($actual -eq $desired) -or ($actual -eq "NOT SET")

        if ($clean) {
            Write-Log ("  PASS: {0} = {1}" -f $valueName, $actual) "SUCCESS"
        } else {
            Write-Log ("  FAIL: {0} = {1} (expected {2})" -f $valueName, $actual, $desired) "ERROR"
            $allClean = $false
        }
    }

    return $allClean
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — PRINT SPOOLER HARDENING (OPTIONAL)
# ─────────────────────────────────────────────────────────────────────────────
function Set-SpoolerHardening {
    $spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue

    if (-not $spooler) {
        Write-Log "Print Spooler service not found on this system." "WARN"
        return
    }

    Write-Log ("--- Print Spooler: current state = {0}, startup = {1} ---" -f $spooler.Status, $spooler.StartType)

    if ($DisableSpooler) {
        # Full disable — use only on non-printing machines
        if ($PSCmdlet.ShouldProcess("Print Spooler", "Stop and disable service")) {
            Stop-Service   -Name Spooler -Force -ErrorAction SilentlyContinue
            Set-Service    -Name Spooler -StartupType Disabled
            Write-Log "  Print Spooler STOPPED and DISABLED." "SUCCESS"
            Write-Log "  NOTE: Local and network printing will not function on this machine." "WARN"
        }
    }
    elseif ($RestrictSpoolerToLocal) {
        # Block remote print by setting registry — spooler keeps running for local print
        $spoolerKey = "HKLM:\System\CurrentControlSet\Services\Spooler"
        if ($PSCmdlet.ShouldProcess($spoolerKey, "Set RestrictDriverInstallationToAdministrators + block remote install")) {
            # Require admin to install printer drivers
            Set-ItemProperty -Path $RegBase -Name "RestrictDriverInstallationToAdministrators" -Value 1 -Type DWord -Force
            Write-Log "  Set RestrictDriverInstallationToAdministrators = 1" "SUCCESS"

            # Disable remote spooler connections (blocks WSD/RPC-based exploitation)
            $spoolerParam = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
            if (-not (Test-Path $spoolerParam)) { New-Item -Path $spoolerParam -Force | Out-Null }
            Set-ItemProperty -Path $spoolerParam -Name "RegisterSpoolerRemoteRpcEndPoint" -Value 2 -Type DWord -Force
            Write-Log "  Set RegisterSpoolerRemoteRpcEndPoint = 2 (local only)" "SUCCESS"
            Write-Log "  Spooler remains running for local printing." "SUCCESS"
        }
    }
    else {
        Write-Log "  No spooler changes requested (use -DisableSpooler or -RestrictSpoolerToLocal if needed)." "INFO"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
Initialize-Log

Write-Log "CVE-2021-34527 (PrintNightmare) Remediation — $Hostname"
Write-Log "Running as: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"

# Phase 1: Audit
$before = Get-CurrentState

# Phase 2: Fix registry
Set-RegistryRemediation -Before $before

# Phase 3: Spooler hardening
Set-SpoolerHardening

# Phase 4: Verify
if (-not $WhatIfPreference) {
    $pass = Confirm-Remediation
    if ($pass) {
        Write-Log "Remediation COMPLETE — host is no longer vulnerable via Point and Print registry." "SUCCESS"
    } else {
        Write-Log "One or more checks FAILED. Review log at: $LogFile" "ERROR"
        exit 1
    }
    Write-Log "Log saved to: $LogFile"
    exit 0
} else {
    Write-Log "--- AUDIT MODE: No changes were made ---" "WARN"
    exit 0
}