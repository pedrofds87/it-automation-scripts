# Script: Information rights management
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 234

# Step 1 - Clear MSIP cache
Remove-Item "$env:LOCALAPPDATA\Microsoft\MSIP\*" -Recurse -Force -ErrorAction SilentlyContinue

# Step 2 - Clear Office/RMS credentials
cmdkey /list | Where-Object { $_ -match "MicrosoftOffice|microsoftonline|MicrosoftRMS" } | ForEach-Object {
    $target = ($_ -split "Target: ")[-1].Trim()
    cmdkey /delete:$target
}

# Step 3 - Clear token cache
Remove-Item "$env:LOCALAPPDATA\Microsoft\Office\16.0\Licensing" -Recurse -Force -ErrorAction SilentlyContinue