# Script: Install Tenable on workstation
# Platform: Windows
# Description: #pstanczyk 2024-12-05
# NinjaOne Script ID: 145

# Define paths
$TenableInstallerUrl = "https://sensor.cloud.tenable.com/install/agent/installer/ms-install-script.ps1"
$TenableScriptPath = "$env:TEMP\ms-install-script.ps1"
$TenableKey = "cbda26ae4c08a6a91fb547497aaab6ee5e0f18bee5057fc24f7a6006ba851a1e"
$TenableGroups = "Laptop"

# Get station name dynamically
$StationName = $env:COMPUTERNAME

# Install Tenable
Write-Output "Downloading Tenable installer script..."
Invoke-WebRequest -Uri $TenableInstallerUrl -OutFile $TenableScriptPath

if (Test-Path $TenableScriptPath) {
    Write-Output "Tenable installer script downloaded successfully. Running the script..."
    try {
        & $TenableScriptPath -key $TenableKey -type "agent" -name $StationName -groups $TenableGroups
        Write-Output "Tenable installation completed successfully."
        Write-Output "Cleaning up Tenable installer script..."
        Remove-Item -Path $TenableScriptPath -Force
    } catch {
        Write-Output "Error: Tenable installation failed. $_"
        Exit 1
    }
} else {
    Write-Output "Error: Failed to download Tenable installer script."
    Exit 1
}

#pstanczyk 2024-12-05