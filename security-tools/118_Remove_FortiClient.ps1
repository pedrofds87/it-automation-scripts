# Script: Remove FortiClient
# Platform: Windows
# Description: #pstanczyk 2024-11-07
# NinjaOne Script ID: 118

# Define common installation paths for FortiClient
$installPaths = @(
    "C:\Program Files\Fortinet\FortiClient",
    "C:\Program Files (x86)\Fortinet\FortiClient"
)

# Remove FortiClient files if they exist
foreach ($path in $installPaths) {
    if (Test-Path $path) {
        Write-Output "Removing FortiClient directory at $path..."
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "FortiClient directory removed from $path."
    }
}

# Attempt to clean up registry entries
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\FortiClient",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FortiClient",
    "HKLM:\Software\Fortinet\FortiClient",
    "HKLM:\Software\WOW6432Node\Fortinet\FortiClient"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        Write-Output "Removing registry entry at $regPath..."
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "Registry entry removed at $regPath."
    }
}

Write-Output "FortiClient manual cleanup completed."


#pstanczyk 2024-11-07