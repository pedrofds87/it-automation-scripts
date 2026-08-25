# Script: .NET CORE to 8.0.11
# Platform: Windows
# Description: #made by pstanczyk 2024-11-06
# NinjaOne Script ID: 108

# Define the download URL for .NET Core Runtime version 8.0.11
$dotnetDownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/27bcdd70-ce64-4049-ba24-2b14f9267729/d4a435e55182ce5424a7204c2cf2b3ea/windowsdesktop-runtime-8.0.11-win-x64.exe"
$installerPath = "$env:TEMP\dotnet-runtime-8.0.11-installer.exe"
$dotnetCorePath = "C:\Program Files\dotnet\shared\Microsoft.NETCore.App"
$targetVersion = "8.0.11"

# Function to check all installed .NET Core versions
function Get-InstalledDotNetVersions {
    $dotnetPath = "C:\Program Files\dotnet\dotnet.exe"
    if (Test-Path $dotnetPath) {
        $installedVersions = & "$dotnetPath" --list-runtimes | Select-String -Pattern "Microsoft.NETCore.App"
        return $installedVersions
    } else {
        Write-Output ".NET Core executable not found at $dotnetPath."
        return $null
    }
}

# Function to find processes using a specific .NET Core version
function Get-ProcessesUsingDotNetVersion($versionPath) {
    $result = @()
    $allProcesses = Get-Process | Where-Object { $_.Path -ne $null }
    foreach ($process in $allProcesses) {
        try {
            if ($process.Path.StartsWith($versionPath)) {
                $result += [PSCustomObject]@{
                    ProcessName = $process.Name
                    ProcessId = $process.Id
                }
            }
        } catch {
            # Ignore errors for inaccessible processes
        }
    }
    return $result
}

# Install .NET Core 8.0.11
Write-Output "Downloading .NET Core Runtime 8.0.11 installer..."
Invoke-WebRequest -Uri $dotnetDownloadUrl -OutFile $installerPath -UseBasicParsing

if (Test-Path $installerPath) {
    Write-Output "Installing .NET Core Runtime 8.0.11..."
    Start-Process -FilePath $installerPath -ArgumentList "/quiet /install" -Wait
    Write-Output ".NET Core Runtime 8.0.11 installed successfully."
    Remove-Item -Path $installerPath -Force
} else {
    Write-Output "Failed to download the .NET Core Runtime installer."
    Exit
}

# Get all installed versions of .NET Core
Write-Output "Checking all installed .NET Core versions..."
$installedVersions = Get-ChildItem -Path $dotnetCorePath | Where-Object { $_.PSIsContainer }

# Stop processes using older versions
foreach ($version in $installedVersions) {
    if ($version.Name -ne $targetVersion) {
        Write-Output "Checking processes using .NET Core version: $($version.FullName)"
        $processes = Get-ProcessesUsingDotNetVersion -versionPath $version.FullName
        if ($processes.Count -gt 0) {
            foreach ($process in $processes) {
                Write-Output "Stopping process: $($process.ProcessName), ID: $($process.ProcessId)"
                Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Remove older versions
foreach ($version in $installedVersions) {
    if ($version.Name -ne $targetVersion) {
        Write-Output "Removing older .NET Core version: $($version.Name)"
        Remove-Item -Path $version.FullName -Recurse -Force -ErrorAction SilentlyContinue
        if (!(Test-Path -Path $version.FullName)) {
            Write-Output "Successfully removed $($version.Name)."
        } else {
            Write-Output "Failed to remove $($version.Name). Ensure no processes are using this version."
        }
    }
}

Write-Output "Script completed. .NET Core 8.0.11 is installed, and older versions have been removed."


#made by pstanczyk 2024-11-06