# Script: check MS Teams version  and path
# Platform: Windows
# Description: #made by pstanczyk 2024-11-06
# NinjaOne Script ID: 112

# Define potential paths for Microsoft Teams installations
$paths = @(
    "C:\Program Files\Microsoft\Teams\current\Teams.exe",               # System-wide installation path
    "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"               # User-specific installation path
)

# Loop through the paths to check for installed versions of Teams
$found = $false
foreach ($path in $paths) {
    if (Test-Path -Path $path) {
        # Retrieve the version information
        $teamsVersion = (Get-Item -Path $path).VersionInfo.ProductVersion
        Write-Output "Microsoft Teams is installed at: $path"
        Write-Output "Version: $teamsVersion"
        $found = $true
    }
}

# If no installation is found
if (-not $found) {
    Write-Output "Microsoft Teams is not installed in the expected locations."
}

#made by pstanczyk 2024-11-06