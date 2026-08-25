# Script: checking what is running .ASP NET
# Platform: Windows
# Description: #pstanczyk 2024-11-20
# NinjaOne Script ID: 133

# Define paths to check
$pathsToCheck = @(
    "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\6.0.36",
    "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\3.1.32"
)

# Function to get processes using a specific .NET version
function Get-ProcessesUsingDotNet {
    param (
        [string]$dotnetPath
    )
    Write-Output "Checking processes using .NET Core version at: $dotnetPath..."
    $processes = Get-Process | Where-Object {
        $_.Modules | ForEach-Object { $_.FileName -like "$dotnetPath*" }
    } | Select-Object -Property ProcessName, Id
    if ($processes) {
        Write-Output "Processes using ${dotnetPath}:"
        $processes | ForEach-Object {
            Write-Output "Process Name: $($_.ProcessName), ID: $($_.Id)"
        }
    } else {
        Write-Output "No processes are currently using ${dotnetPath}."
    }
}

# Iterate through the paths and check for processes
foreach ($path in $pathsToCheck) {
    Get-ProcessesUsingDotNet -dotnetPath $path
}


#pstanczyk 2024-11-20