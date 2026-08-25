# Script: Umbrella Installation
# Platform: Windows
# Description: # pstanczyk 2024-12-04
# NinjaOne Script ID: 143

# Define paths for the local files
$UmbrellaInstallerPath = "C:\Users\Public\Deployment\Setup.msi"
$CertificatePath = "C:\Users\Public\Deployment\Cisco_Umbrella_Root_CA.cer"

# Define Umbrella installation parameters
$OrgID = "1988383"
$OrgFingerprint = "b545f1925d2b0b9d44212bddcb8640eb"
$UserID = "6163897"
$InstallArgs = "/quiet ORG_ID=$OrgID ORG_FINGERPRINT=$OrgFingerprint USER_ID=$UserID"

# Step 1: Install Umbrella
if (Test-Path $UmbrellaInstallerPath) {
    Write-Output "Umbrella installer found. Starting installation with parameters..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$UmbrellaInstallerPath`" $InstallArgs" -Wait
    if ($?) {
        Write-Output "Umbrella installation completed successfully."
    } else {
        Write-Output "Error: Umbrella installation failed."
        Exit 1
    }
} else {
    Write-Output "Error: Umbrella installer not found at $UmbrellaInstallerPath."
    Exit 1
}

# Step 2: Apply the Certificate to Intermediate Certification Authorities
if (Test-Path $CertificatePath) {
    Write-Output "Certificate found. Installing to Intermediate Certification Authorities store..."
    try {
        # Import the certificate to the Intermediate Certification Authorities store
        Import-Certificate -FilePath $CertificatePath -CertStoreLocation Cert:\LocalMachine\CA
        Write-Output "Certificate installed successfully to the Intermediate Certification Authorities store."
    } catch {
        Write-Output "Error: Failed to install the certificate. $_"
        Exit 1
    }
} else {
    Write-Output "Error: Certificate not found at $CertificatePath."
    Exit 1
}

Write-Output "Umbrella deployment completed successfully."




# pstanczyk 2024-12-04 