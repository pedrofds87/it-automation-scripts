# Script: Defender update + scan script
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 217

Write-Host "=== Microsoft Defender Update & Scan ===" -ForegroundColor Cyan

# Check Defender service
$defenderService = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
if (-not $defenderService) {
    Write-Host "'L Defender service not found. Is Defender installed?" -ForegroundColor Red
    exit
}

Write-Host "Updating Defender signatures..." -ForegroundColor Yellow

# Update Defender signatures
Update-MpSignature

# Show current version
$status = Get-MpComputerStatus
Write-Host "Signature Version: $($status.AntivirusSignatureVersion)" -ForegroundColor Green
Write-Host "Last Updated: $($status.AntivirusSignatureLastUpdated)" -ForegroundColor Green

Write-Host ""

# Run quick scan
Write-Host "Starting quick scan..." -ForegroundColor Yellow
Start-MpScan -ScanType QuickScan

Write-Host ""
Write-Host "=== Completed ===" -ForegroundColor Cyan