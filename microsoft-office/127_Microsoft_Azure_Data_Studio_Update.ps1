# Script: Microsoft Azure Data Studio Update
# Platform: Windows
# Description: #pstanczyk 2024-11-8
# NinjaOne Script ID: 127

# Variables
$tempDir = "$env:TEMP\AzureDataStudioUpdate"
$installerPath = "$tempDir\AzureDataStudioSetup.exe"
$downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2282377"
$azureDataStudioPath = "C:\Program Files\Azure Data Studio\"

# Create temporary directory
if (-Not (Test-Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory | Out-Null
}

# Check for existing installation
if (-Not (Test-Path $azureDataStudioPath)) {
    Write-Output "Azure Data Studio is not installed on this system."
    exit 1
}

# Download the installer
Write-Output "Downloading the latest Azure Data Studio installer..."
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -Headers @{"User-Agent" = "Mozilla/5.0"}
    Write-Output "Download completed successfully."
} catch {
    Write-Output "Error downloading the installer: $_"
    exit 1
}

# Close Azure Data Studio if running
Write-Output "Closing any running instances of Azure Data Studio..."
Get-Process -Name "Azure Data Studio" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Run the installer
Write-Output "Installing the latest version of Azure Data Studio..."
try {
    Start-Process -FilePath $installerPath -ArgumentList "/quiet /norestart" -Wait
    Write-Output "Azure Data Studio has been updated successfully."
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

#pstanczyk 2024-11-8