# Script: rdp self certificate
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 226

$certPath = "\\fitfoods.local\SYSVOL\fitfoods.local\scripts\FitFoods-RDP-Signing.cer"
$thumbprint = "474562B75882E8F9FD98E0FB220C170C3C3513FF"

Write-Host "=== Deploy RDP Signing Certificate ==="

if (-not (Test-Path $certPath)) {
    Write-Host "Certificate file not found: $certPath"
    exit 1
}

$existing = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $thumbprint }

if ($existing) {
    Write-Host "Certificate already exists in Trusted Root."
    exit 0
}

try {
    Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
    Write-Host "Certificate imported successfully into Local Computer Trusted Root."
} catch {
    Write-Host "Failed to import certificate: $($_.Exception.Message)"
    exit 1
}

$verify = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $thumbprint }

if ($verify) {
    Write-Host "Verification successful. Certificate is trusted."
    exit 0
} else {
    Write-Host "Certificate import could not be verified."
    exit 1
}