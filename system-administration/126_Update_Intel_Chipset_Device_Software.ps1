# Script: Update Intel Chipset Device Software
# Platform: Windows
# Description: #pstanczyk 2024-11-08
# NinjaOne Script ID: 126

# Variables
$tempDir = "$env:TEMP\IntelChipsetUpdate"
$installerPath = "$tempDir\SetupChipset.exe"
$downloadUrl = "https://downloadmirror.intel.com/831096/SetupChipset.exe"

# Create temporary directory
if (-Not (Test-Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory | Out-Null
}

# Download the installer
Write-Output "Downloading Intel Chipset Device Software..."
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -Headers @{"User-Agent" = "Mozilla/5.0"}
    Write-Output "Download completed successfully."
} catch {
    Write-Output "Error downloading file: $_"
    exit 1
}

# Run the installer
Write-Output "Installing Intel Chipset Device Software..."
try {
    Start-Process -FilePath $installerPath -ArgumentList "/quiet /norestart" -Wait
    Write-Output "Intel Chipset Device Software has been updated successfully."
} catch {
    Write-Output "Error during installation: $_"
    exit 1
}

# Cleanup
Write-Output "Cleaning up temporary files..."
try {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Output "Temporary files cleaned up."
} catch {
    Write-Output "Error cleaning up temporary files: $_"
}

Write-Output "Process completed."



#pstanczyk 2024-11-08