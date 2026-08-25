# Script: update Zoom
# Platform: Windows
# Description: #pstanczyk 2024-11-07
# NinjaOne Script ID: 119

# Define paths and URLs
$zoomPath = "$env:APPDATA\Zoom\bin\Zoom.exe"
$downloadUrl = "https://zoom.us/client/latest/ZoomInstaller.exe"
$installerPath = "$env:TEMP\ZoomInstaller.exe"

# Check if Zoom is installed and outdated
if (Test-Path -Path $zoomPath) {
    # Get the current version installed
    $currentVersion = (Get-Item $zoomPath).VersionInfo.ProductVersion
    Write-Output "Installed Zoom version: $currentVersion"
    
    # Define the required version
    $requiredVersion = [Version]"5.13.3"
    if ([Version]$currentVersion -lt $requiredVersion) {
        Write-Output "Zoom is outdated. Updating to the latest version..."
        
        # Download the latest Zoom installer
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

        # Install Zoom
        Write-Output "Installing Zoom..."
        Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait

        # Clean up the installer
        Remove-Item -Path $installerPath -Force
        Write-Output "Zoom has been updated to the latest version."
    } else {
        Write-Output "Zoom is already up-to-date."
    }
} else {
    Write-Output "Zoom is not installed on this system."
}

#pstanczyk 2024-11-07