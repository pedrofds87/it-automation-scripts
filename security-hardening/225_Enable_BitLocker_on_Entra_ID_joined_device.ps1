# Script: Enable BitLocker on Entra ID joined device
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 225

# Enable BitLocker on Entra ID joined device and back up recovery key to Entra ID
# Run as Administrator or SYSTEM

$mountPoint = "C:"

Write-Host "=== BitLocker Enablement ===" -ForegroundColor Cyan

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit 1
}

# Reliable Entra join check
Write-Host "Checking Microsoft Entra join status..." -ForegroundColor Yellow
$dsreg = (dsregcmd /status) 2>&1 | Out-String

Write-Host $dsreg

$entraJoined = $false

if ($dsreg -match 'AzureAdJoined\s*:\s*YES') {
    $entraJoined = $true
}

# Fallback check via registry
if (-not $entraJoined) {
    try {
        $joinInfo = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo" -ErrorAction Stop
        if ($joinInfo) {
            $entraJoined = $true
        }
    } catch {}
}

if (-not $entraJoined) {
    Write-Host "This device does not appear to be Microsoft Entra joined." -ForegroundColor Red
    exit 1
}

Write-Host "Microsoft Entra join detected." -ForegroundColor Green

# Check TPM
Write-Host "Checking TPM..." -ForegroundColor Yellow
$tpm = Get-Tpm
if (-not $tpm.TpmPresent) {
    Write-Host "TPM is not present. Cannot proceed with TPM-based BitLocker." -ForegroundColor Red
    exit 1
}

if (-not $tpm.TpmReady) {
    Write-Host "TPM is present but not ready." -ForegroundColor Red
    exit 1
}

# Check BitLocker status
$blv = Get-BitLockerVolume -MountPoint $mountPoint

if ($blv.ProtectionStatus -eq "On") {
    Write-Host "BitLocker is already enabled on $mountPoint." -ForegroundColor Green

    $recoveryProtector = $blv.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } | Select-Object -First 1
    if ($recoveryProtector) {
        try {
            BackupToAAD-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $recoveryProtector.KeyProtectorId
            Write-Host "Existing recovery key backed up to Microsoft Entra ID." -ForegroundColor Green
        } catch {
            Write-Host "BitLocker is on, but recovery key backup to Entra ID could not be confirmed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    exit 0
}

# Add recovery password protector
Write-Host "Adding Recovery Password protector..." -ForegroundColor Yellow
Add-BitLockerKeyProtector -MountPoint $mountPoint -RecoveryPasswordProtector | Out-Null

$blv = Get-BitLockerVolume -MountPoint $mountPoint
$recoveryProtector = $blv.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } | Select-Object -First 1

if (-not $recoveryProtector) {
    Write-Host "Failed to create Recovery Password protector." -ForegroundColor Red
    exit 1
}

# Enable BitLocker
Write-Host "Enabling BitLocker..." -ForegroundColor Yellow
Enable-BitLocker -MountPoint $mountPoint -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector | Out-Null

Start-Sleep -Seconds 5

# Back up key to Entra ID
Write-Host "Backing up recovery key to Microsoft Entra ID..." -ForegroundColor Yellow
try {
    BackupToAAD-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $recoveryProtector.KeyProtectorId
    Write-Host "Recovery key successfully backed up to Microsoft Entra ID." -ForegroundColor Green
} catch {
    Write-Host "BitLocker enabled, but failed to back up key to Entra ID: $($_.Exception.Message)" -ForegroundColor Yellow
}

$blv = Get-BitLockerVolume -MountPoint $mountPoint
Write-Host "Protection Status: $($blv.ProtectionStatus)" -ForegroundColor Green
Write-Host "Volume Status: $($blv.VolumeStatus)" -ForegroundColor Green
Write-Host "Encryption Percentage: $($blv.EncryptionPercentage)" -ForegroundColor Green
Write-Host "=== Completed ===" -ForegroundColor Cyan