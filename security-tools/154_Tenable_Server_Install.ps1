# Script: Tenable Server Install
# Platform: Windows
# Description: pstanczyk
# NinjaOne Script ID: 154


# Force PowerShell to use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# Define paths
$TenableInstallerUrl = "https://sensor.cloud.tenable.com/install/agent/installer/ms-install-script.ps1"
$TenableScriptPath = "$env:TEMP\ms-install-script.ps1"
$TenableKey = "YOUR_TENABLE_LINKING_KEY"    # Get from Tenable.io > Sensors > Nessus Agents > Add Agent
$TenableGroups = "Server"


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
