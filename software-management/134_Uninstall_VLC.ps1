# Script: Uninstall VLC
# Platform: Windows
# Description: #pstanczyk 2024-11-21
# NinjaOne Script ID: 134

# Define the VLC installation path
$vlcPath = "C:\Program Files\VideoLAN\VLC"

# Check if VLC is installed
if (Test-Path -Path $vlcPath) {
    Write-Output "VLC Media Player found at $vlcPath. Proceeding with uninstallation..."
    
    # Attempt to stop any running VLC processes
    $vlcProcesses = Get-Process -Name "vlc" -ErrorAction SilentlyContinue
    if ($vlcProcesses) {
        Write-Output "Stopping running VLC processes..."
        Stop-Process -Name "vlc" -Force
    }
    
    # Remove VLC folder
    Write-Output "Removing VLC directory..."
    try {
        Remove-Item -Recurse -Force -Path $vlcPath
        Write-Output "VLC Media Player successfully removed."
    } catch {
        Write-Output "Failed to remove VLC directory. Error: $_"
    }
} else {
    Write-Output "VLC Media Player is not installed at $vlcPath."
}


#pstanczyk 2024-11-21