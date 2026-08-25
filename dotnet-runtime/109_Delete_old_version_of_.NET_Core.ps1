# Script: Delete old version of .NET Core
# Platform: Windows
# Description: #made by pstanczyk 2024-11-06
# NinjaOne Script ID: 109

# Define the directory containing .NET Core versions and the version to keep
$dotnetCorePath = "C:\Program Files\dotnet\shared\Microsoft.NETCore.App"
$latestVersion = "8.0.10"

# Check if the directory exists
if (Test-Path -Path $dotnetCorePath) {
    # Get all subdirectories (representing installed versions)
    $installedVersions = Get-ChildItem -Path $dotnetCorePath | Where-Object { $_.PSIsContainer }

    foreach ($version in $installedVersions) {
        if ($version.Name -ne $latestVersion) {
            Write-Output "Deleting .NET Core version: $($version.Name)"
            Remove-Item -Path $version.FullName -Recurse -Force
        } else {
            Write-Output "Keeping .NET Core version: $($version.Name)"
        }
    }
    Write-Output "Cleanup complete. Only .NET Core version $latestVersion is retained."
} else {
    Write-Output "Directory $dotnetCorePath does not exist."
}

#made by pstanczyk 2024-11-06