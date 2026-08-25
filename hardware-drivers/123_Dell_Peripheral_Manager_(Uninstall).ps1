# Script: Dell Peripheral Manager (Uninstall)
# Platform: Windows
# Description: #pstanczyk 2024-11-08
# NinjaOne Script ID: 123

# Define variables
$softwarePath = "C:\Program Files\Dell\Dell Peripheral Manager"
$installedVersion = "1.6.7.0"
$fixedVersion = "1.7.6"
$uninstallKey = "Dell Peripheral Manager"
$logFile = "$env:TEMP\DellPeripheralManager_Uninstall.log"

# Logging function
Function Log {
    param ([string]$message)
    Add-Content -Path $logFile -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $message"
}

Log "Starting uninstallation of Dell Peripheral Manager..."

# Check if the software exists
if (Test-Path $softwarePath) {
    Log "Dell Peripheral Manager found at $softwarePath with version $installedVersion."

    # Close any running processes related to the software
    Log "Stopping any running processes of Dell Peripheral Manager..."
    Get-Process -Name "DellPeripheralManager" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    # Uninstall using the product name from registry
    $uninstallCmd = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName -like "*$uninstallKey*" } | Select-Object -ExpandProperty UninstallString

    if ($uninstallCmd) {
        Log "Uninstallation command found: $uninstallCmd"
        & cmd.exe /c $uninstallCmd /quiet /norestart
        Log "Uninstallation completed."
    } else {
        Log "Uninstallation command not found in the registry."
    }

    # Remove leftover files and folders
    Log "Removing leftover files and folders..."
    Remove-Item -Path $softwarePath -Recurse -Force -ErrorAction SilentlyContinue
    Log "Leftover files removed."
} else {
    Log "Dell Peripheral Manager not found at $softwarePath. No action taken."
}

# Verify removal
if (-Not (Test-Path $softwarePath)) {
    Log "Dell Peripheral Manager successfully removed."
} else {
    Log "Dell Peripheral Manager removal failed. Please check permissions or try again manually."
}

Log "Script execution completed."


#pstanczyk 2024-11-08