# Script: Remove Dell Display manager
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 157

# PowerShell script to run the Dell Display Manager uninstaller with no user interaction

# Specify the path to the uninstaller
$uninstallerPath = "C:\Program Files\Dell\Dell Display Manager 2\uninst.exe"

# Check if the uninstaller exists
if (Test-Path $uninstallerPath) {
    # Execute the uninstaller with the /VERYSILENT parameter
    Start-Process $uninstallerPath -ArgumentList "/VERYSILENT" -Wait
    Write-Output "Dell Display Manager has been successfully uninstalled."
} else {
    # Output a message if the uninstaller does not exist
    Write-Output "Uninstaller not found. Please check the path and try again."
}
#pstanczyk