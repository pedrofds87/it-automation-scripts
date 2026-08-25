# Script: Sophos Instalation
# Platform: Windows
# Description: #pstanczyk 2024-12-04
# NinjaOne Script ID: 142

# Define the download URL and the local path for the installer
$DownloadUrl = "https://api-cloudstation-us-east-2.prod.hydra.sophos.com/api/download/ef31545ad98202fa38b86143a7a31ecd/SophosSetup.exe"
$InstallerPath = "$env:TEMP\SophosSetup.exe"

# Download the installer
Write-Output "Downloading Sophos installer..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -Headers @{'User-Agent'='Mozilla/5.0'}

# Check if the installer was downloaded
if (Test-Path $InstallerPath) {
    Write-Output "Download completed. Running the installer silently..."
    
    # Run the installer silently
    Start-Process -FilePath $InstallerPath -ArgumentList "--quiet" -Wait
    
    Write-Output "Installation completed successfully."

    # Optional: Clean up the installer file
    Write-Output "Cleaning up the installer file..."
    Remove-Item -Path $InstallerPath -Force
} else {
    Write-Output "Error: Failed to download the installer."
}

#pstanczyk 2024-12-04