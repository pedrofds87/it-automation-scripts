# Script: Update .NET Core (6.0.35)
# Platform: Windows
# Description: #made by pstanczyk 2024-11-06
# NinjaOne Script ID: 110

# Define the updated download URL for .NET Core Runtime version 6.0.35
$dotnetDownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/c4f65621-b36b-46a9-8380-d5b660bef27e/0185fd72055dcdca86166b99add71686/dotnet-runtime-6.0.35-win-x64.exe"
$installerPath = "$env:TEMP\dotnet-runtime-6.0.35-installer.exe"
$dotnetCorePath = "C:\Program Files\dotnet\shared\Microsoft.NETCore.App"
$latestVersion = "6.0.35"

# Function to check if .NET Core version 6.0.32 is installed
function Get-InstalledDotNetVersion {
    $dotnetPath = "C:\Program Files\dotnet\dotnet.exe"
    if (Test-Path $dotnetPath) {
        $installedVersion = & "$dotnetPath" --list-runtimes | Select-String -Pattern "Microsoft.NETCore.App 6.0.32"
        return $installedVersion -ne $null
    } else {
        Write-Output ".NET Core executable not found at $dotnetPath."
        return $false
    }
}

# Download and install the update if version 6.0.32 is installed
if (Get-InstalledDotNetVersion) {
    Write-Output "Outdated version of .NET Core detected (6.0.32). Proceeding with update to 6.0.35..."
    
    # Download the installer for .NET Core Runtime 6.0.35
    Write-Output "Downloading .NET Core Runtime 6.0.35 installer..."
    Invoke-WebRequest -Uri $dotnetDownloadUrl -OutFile $installerPath -UseBasicParsing
    
    # Run the installer in silent mode
    if (Test-Path $installerPath) {
        Write-Output "Installing .NET Core Runtime 6.0.35..."
        Start-Process -FilePath $installerPath -ArgumentList "/quiet /install" -Wait
        
        # Clean up installer file
        Remove-Item -Path $installerPath -Force
        Write-Output ".NET Core Runtime updated to 6.0.35 successfully."
        
        # Remove older versions after updating
        if (Test-Path -Path $dotnetCorePath) {
            $installedVersions = Get-ChildItem -Path $dotnetCorePath | Where-Object { $_.PSIsContainer }
            foreach ($version in $installedVersions) {
                if ($version.Name -ne $latestVersion) {
                    Write-Output "Deleting older .NET Core version: $($version.Name)"
                    Remove-Item -Path $version.FullName -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Write-Output "Keeping .NET Core version: $($version.Name)"
                }
            }
            Write-Output "Cleanup complete. Only .NET Core version $latestVersion is retained."
        } else {
            Write-Output "Directory $dotnetCorePath does not exist."
        }
    } else {
        Write-Output "Failed to download .NET Core Runtime installer."
    }
} else {
    Write-Output ".NET Core 6.0.32 not found or already updated."
}

#made by pstanczyk 2024-11-06
