# Script: Remove .net core 6.0.36
# Platform: Windows
# Description: #pstanczyk 2024-12-03
# NinjaOne Script ID: 138

# Define the path of the runtime to be uninstalled
$RuntimePath = "C:\Program Files\dotnet\shared\Microsoft.NetCore.App\6.0.36"

# Function to identify and stop processes using the runtime
Function Stop-BlockingProcesses {
    Write-Output "Identifying processes using $RuntimePath..."
    
    # Find processes using the runtime path
    $Processes = Get-Process | Where-Object {
        $_.Modules | Where-Object { $_.FileName -like "$RuntimePath*" }
    } 2>$null

    if ($Processes) {
        Write-Output "Stopping the following processes:"
        $Processes | ForEach-Object { Write-Output " - $_.Name (ID: $_.Id)" }

        # Stop each process
        $Processes | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
        Write-Output "All blocking processes have been stopped."
    } else {
        Write-Output "No blocking processes found."
    }
}

# Function to forcefully delete the runtime directory
Function Force-UninstallRuntime {
    Write-Output "Attempting to forcefully remove the runtime directory: $RuntimePath"

    # Take ownership of the directory
    Write-Output "Taking ownership of the directory..."
    takeown /f "$RuntimePath" /r /d y | Out-Null
    #icacls "$RuntimePath" /grant "%username%:F" /t | Out-Null
    icacls "C:\Program Files\dotnet\shared\Microsoft.NetCore.App\6.0.36" /grant "Administrators:F" /t


    # Remove the directory
    Remove-Item -Path "$RuntimePath" -Recurse -Force -ErrorAction SilentlyContinue

    # Verify deletion
    if (!(Test-Path $RuntimePath)) {
        Write-Output "Runtime successfully removed."
    } else {
        Write-Output "Failed to remove the runtime. Please check permissions or locked files."
    }
}

# Main script execution
Write-Output "Starting process to remove .NET Core Runtime 6.0.36..."
Stop-BlockingProcesses
Force-UninstallRuntime
Write-Output "Process completed."

#pstanczyk 2024-12-03