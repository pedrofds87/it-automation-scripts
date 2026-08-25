# Script: Remove MS Teams specific user
# Platform: Windows
# Description: It needs the user as a parameter #made by pstanczyk 2024-11-06
# NinjaOne Script ID: 113


[string]$targetUsername = $env:tst


# Define the user-specific Teams path based on the provided targetUsername parameter
$teamsPath = "C:\Users\$targetUsername\AppData\Local\Microsoft\Teams"

# Check if Teams is installed in the user-specific path and uninstall it if found
if (Test-Path $teamsPath) {
    Write-Output "Uninstalling Microsoft Teams for user $targetUsername..."
    Stop-Process -Name Teams -Force -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force -Path $teamsPath
    Write-Output "Microsoft Teams has been uninstalled for user $targetUsername."
} else {
    Write-Output "Microsoft Teams is not found in the specified user path for user $targetUsername."
}


#made by pstanczyk 2024-11-06