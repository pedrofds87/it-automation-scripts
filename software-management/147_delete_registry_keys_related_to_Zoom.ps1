# Script: delete registry keys related to Zoom
# Platform: Windows
# Description: #pstanczyk 2024-12-06
# NinjaOne Script ID: 147

# Function to search and delete registry keys related to Zoom
function Remove-ZoomRegistryEntries {
    Write-Output "Starting registry cleanup for Zoom entries..."
    
    # Define registry paths to search for Zoom entries
    $registryPaths = @(
        "HKLM:\SOFTWARE",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node",
        "HKCU:\SOFTWARE"
    )

    foreach ($path in $registryPaths) {
        try {
            Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match "Zoom"
            } | ForEach-Object {
                Write-Output "Removing registry key: $($_.Name)"
                Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Output "Error processing registry path: $path. $_"
        }
    }

    Write-Output "Registry cleanup for Zoom completed."
}

# Function to clean up temporary files and remnants
function Clean-TemporaryFiles {
    Write-Output "Starting temporary file cleanup..."

    # Define common paths for temporary files and Zoom remnants
    $tempPaths = @(
        "$env:LOCALAPPDATA\Temp",
        "$env:APPDATA\Zoom",
        "$env:LOCALAPPDATA\Zoom",
        "C:\ProgramData\Zoom",
        "C:\Users\*\AppData\Roaming\Zoom",
        "C:\Users\*\AppData\Local\Zoom"
    )

    foreach ($path in $tempPaths) {
        try {
            # Resolve wildcard paths
            $resolvedPaths = Resolve-Path -Path $path -ErrorAction SilentlyContinue
            foreach ($resolvedPath in $resolvedPaths) {
                Write-Output "Removing folder: $resolvedPath"
                Remove-Item -Path $resolvedPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Output "Error cleaning path: $path. $_"
        }
    }

    Write-Output "Temporary file cleanup completed."
}

# Main Script Execution
Write-Output "Starting Zoom cleanup process..."

# Step 1: Clean registry entries
Remove-ZoomRegistryEntries

# Step 2: Clean temporary files
Clean-TemporaryFiles

Write-Output "Zoom cleanup process completed."

#pstanczyk 2024-12-06
