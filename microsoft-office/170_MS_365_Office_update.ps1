# Script: MS 365 Office update
# Platform: Windows
# Description: # Force Office to update to the latest version on the Current Channel #pstanczyk
# NinjaOne Script ID: 170

# Force Office to update to the latest version on the Current Channel
$OfficeUpdatePath = "${env:ProgramFiles}\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"

if (Test-Path $OfficeUpdatePath) {
    Start-Process -FilePath $OfficeUpdatePath -ArgumentList "/update user updatetoversion=Latest" -Wait
    Write-Host "Office update initiated successfully."
} else {
    Write-Host "Office Click-to-Run update tool not found. Please check the Office installation."
}

#pstanczyk