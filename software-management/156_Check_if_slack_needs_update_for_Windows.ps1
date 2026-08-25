# Script: Check if slack needs update for Windows
# Platform: Windows
# Description: pstanczyk
# NinjaOne Script ID: 156

# Define the package ID for Slack
$PackageID = "SlackTechnologies.Slack"

# Step 1: Check if Slack needs an update
Write-Output "Checking if Slack needs an update..."
$UpgradeInfo = winget upgrade --id=$PackageID --accept-source-agreements | Out-String

if ($UpgradeInfo -match "No available upgrade found") {
    Write-Output "Slack is up to date. No updates available."
} elseif ($UpgradeInfo -match $PackageID) {
    Write-Output "An update for Slack is available. Updating now..."
    # Step 2: Apply the update
    winget upgrade --id=$PackageID --accept-source-agreements --silent
    Write-Output "Slack has been successfully updated."
} else {
    Write-Output "Could not determine the update status of Slack."
    Exit 1
}


#pstanczyk