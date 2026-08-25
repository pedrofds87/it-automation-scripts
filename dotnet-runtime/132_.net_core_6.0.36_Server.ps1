# Script: .net core 6.0.36 Server
# Platform: Windows
# Description: #pstanczyk 2024-11-19
# NinjaOne Script ID: 132

# Define variables
$dotnetDownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/0f0ea01c-ef7c-4493-8960-d1e9269b718b/3f95c5bd383be65c2c3384e9fa984078/aspnetcore-runtime-6.0.36-win-x64.exe"
$installerPath = "$env:TEMP\dotnet-runtime-6.0.36-installer.exe"
$dotnetCorePath = "C:\Program Files\dotnet\shared\Microsoft.NetCore.App"
$latestVersion = "6.0.36"

# Function to list processes using .NET Core
function Get-ProcessesUsingDotNetCore {
    param ([string]$versionPath)
    Write-Output "Checking processes using .NET Core version at: $versionPath..."
    $processes = Get-Process | ForEach-Object {
        $_.Modules | Where-Object { $_.FileName -like "$versionPath\*" } | ForEach-Object {
            [PSCustomObject]@{
                ProcessName = $_.ProcessName
                ProcessId   = $_.BaseAddress.ProcessId
            }
        }
    }
    return $processes
}

# Function to stop processes
function Stop-Processes {
    param ([Array]$processes)
    foreach ($process in $processes) {
        Write-Output "Stopping process: $($process.ProcessName), ID: $($process.ProcessId)..."
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

# Function to restart processes
function Restart-Processes {
    param ([Array]$processes)
    foreach ($process in $processes) {
        Write-Output "Restarting process: $($process.ProcessName)..."
        Start-Process -FilePath $process.ProcessName -ErrorAction SilentlyContinue
    }
}

# Check for processes using the outdated .NET Core version
$outdatedVersionPath = "$dotnetCorePath\6.0.32"
$processesUsingOutdatedVersion = Get-ProcessesUsingDotNetCore -versionPath $outdatedVersionPath

if ($processesUsingOutdatedVersion) {
    Write-Output "Processes using the outdated .NET Core version: $outdatedVersionPath"
    $processesUsingOutdatedVersion | Format-Table -AutoSize
} else {
    Write-Output "No processes are currently using the outdated .NET Core version."
}

# Stop processes using the outdated .NET Core version
Stop-Processes -processes $processesUsingOutdatedVersion

# Download and update to the latest .NET Core version
Write-Output "Downloading .NET Core Runtime $latestVersion installer..."
Invoke-WebRequest -Uri $dotnetDownloadUrl -OutFile $installerPath -UseBasicParsing

if (Test-Path $installerPath) {
    Write-Output "Installing .NET Core Runtime $latestVersion..."
    Start-Process -FilePath $installerPath -ArgumentList "/quiet /install" -Wait
    Remove-Item -Path $installerPath -Force
    Write-Output ".NET Core Runtime updated to $latestVersion successfully."
} else {
    Write-Output "Failed to download .NET Core Runtime installer."
}

# Restart processes that were stopped
Restart-Processes -processes $processesUsingOutdatedVersion

Write-Output "Script execution complete."



#pstanczyk 2024-11-19