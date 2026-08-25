# Script: update MS Teams 
# Platform: Windows
# Description: #made by pstanczyk 2024-11-06
# NinjaOne Script ID: 111

# Download the latest Microsoft Teams installer for all users
$teamsInstallerUrl = "https://statics.teams.cdn.office.net/production-windows-x64/1.6.00.20074/Teams_windows_x64.exe" # Update as needed
$installerPath = "$env:TEMP\Teams_windows_x64.exe"

Write-Output "Downloading the latest Microsoft Teams installer..."
Invoke-WebRequest -Uri $teamsInstallerUrl -OutFile $installerPath -UseBasicParsing

# Install Teams for all users
Write-Output "Installing Microsoft Teams system-wide..."
Start-Process -FilePath $installerPath -ArgumentList "/allusers /silent" -Wait

# Clean up installer file
Remove-Item -Path $installerPath -Force
Write-Output "Microsoft Teams has been installed system-wide."



#made by pstanczyk 2024-11-06