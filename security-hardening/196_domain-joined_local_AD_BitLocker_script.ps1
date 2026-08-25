# Script: domain-joined / local AD BitLocker script
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 196

#requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$MountPoint = "C:"

function Log($m) { Write-Output "$(Get-Date -Format s)  $m" }

# Only run on domain-joined machines
$cs = Get-CimInstance Win32_ComputerSystem
if (-not $cs.PartOfDomain) {
    Log "Not domain-joined. Exiting (no changes)."
    exit 0
}
Log "Domain-joined machine detected: $($cs.Domain)"

# Get BitLocker volume
try {
    $blv = Get-BitLockerVolume -MountPoint $MountPoint
} catch {
    Log "Get-BitLockerVolume failed: $($_.Exception.Message)"
    exit 1
}

Log "Current: VolumeStatus=$($blv.VolumeStatus) ProtectionStatus=$($blv.ProtectionStatus) Encryption=$($blv.EncryptionPercentage)%"

# Exit if already protected
if ($blv.ProtectionStatus -eq "On") {
    Log "BitLocker protection already ON. Nothing to do."
    exit 0
}

# Add protectors if missing
$kps = @($blv.KeyProtector)
$hasTPM = $kps.Where({ $_.KeyProtectorType -eq "Tpm" }).Count -gt 0
$hasRecovery = $kps.Where({ $_.KeyProtectorType -eq "RecoveryPassword" }).Count -gt 0

# TPM protector
if (-not $hasTPM) {
    $tpmOk = $false
    try {
        $tpm = Get-Tpm
        $tpmOk = ($tpm.TpmPresent -and $tpm.TpmReady)
    } catch { $tpmOk = $false }

    if ($tpmOk) {
        Log "Adding TPM protector..."
        Add-BitLockerKeyProtector -MountPoint $MountPoint -TpmProtector | Out-Null
    } else {
        Log "TPM not present/ready. Skipping TPM protector."
    }
} else {
    Log "TPM protector already present."
}

# Recovery password protector
if (-not $hasRecovery) {
    Log "Adding RecoveryPassword protector..."
    # Capture output but DO NOT print the recovery password
    $out = Add-BitLockerKeyProtector -MountPoint $MountPoint -RecoveryPasswordProtector
    Log "RecoveryPassword protector added."
} else {
    Log "RecoveryPassword protector already present."
}

# Refresh volume
$blv = Get-BitLockerVolume -MountPoint $MountPoint

# Enable BitLocker using manage-bde (most compatible)
if ($blv.VolumeStatus -eq "FullyDecrypted" -or $blv.EncryptionPercentage -eq 0) {
    Log "Volume is decrypted. Enabling BitLocker encryption via manage-bde (used-space-only)..."
    & manage-bde -on $MountPoint -usedspaceonly | Out-Null
} else {
    Log "Volume state is $($blv.VolumeStatus). Skipping encryption start."
}

# Ensure protection is ON (if encryption already exists but protection was off)
try {
    & manage-bde -protectors -enable $MountPoint | Out-Null
    Log "Protection enable attempted via manage-bde."
} catch {
    Log "Protection enable step failed (may be normal if already enabled): $($_.Exception.Message)"
}

# Backup RecoveryPassword to AD DS (best effort)
$blv = Get-BitLockerVolume -MountPoint $MountPoint
$recovery = @($blv.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" })

if ($recovery.Count -gt 0) {
    foreach ($rp in $recovery) {
        try {
            Log "Backing up recovery key to AD DS for protector $($rp.KeyProtectorId)..."
            Backup-BitLockerKeyProtector -MountPoint $MountPoint -KeyProtectorId $rp.KeyProtectorId | Out-Null
            Log "AD DS backup attempted."
        } catch {
            Log "AD DS backup failed (check GPO/DC reachability/permissions): $($_.Exception.Message)"
        }
    }
} else {
    Log "No RecoveryPassword protector found after remediation (unexpected)."
}

# Final status
$final = Get-BitLockerVolume -MountPoint $MountPoint
Log "FINAL: VolumeStatus=$($final.VolumeStatus) ProtectionStatus=$($final.ProtectionStatus) Encryption=$($final.EncryptionPercentage)%"
Log "FINAL Protectors: $(@($final.KeyProtector | ForEach-Object { $_.KeyProtectorType }) -join ', ')"

exit 0
