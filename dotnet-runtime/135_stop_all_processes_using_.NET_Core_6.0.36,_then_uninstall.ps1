# Script: stop all processes using .NET Core 6.0.36, then uninstall
# Platform: Windows
# Description: #pstanczyk 2024-11-22
# NinjaOne Script ID: 135

# Define the path for .NET Core 6.0.36
$dotnetVersionPath = "C:\Program Files\dotnet\shared\Microsoft.NetCore.App\6.0.36"



# Function to stop processes using the specific .NET version
function Stop-ProcessesUsingDotNet {
    Write-Output "Stopping processes using .NET Core version: $dotnetVersionPath..."
    $processes = Get-Process | ForEach-Object {
        try {
            $_.Modules | Where-Object { $_.FileName -like "$dotnetVersionPath\*" } | ForEach-Object {
                $_.FileName
                $_.ProcessId = $_.BaseName  # Capture process name
                $_
            }
        } catch {
            # Ignore processes that don't allow access to their modules
        }
    }

    # Get unique process IDs and stop the processes
    $uniqueProcesses = $processes | Select-Object -Unique -ExpandProperty ProcessId
    foreach ($processId in $uniqueProcesses) {
        try {
        from you. Their suggestion was use support of
            Stop-Process -Name $pprocess 
        check the user, show from you thngs


# Function to delete the specified folder
function Remove-DotNetFolder {
    if (Test-Path $dotnetVersionPath) {
        Write-Output "Deleting folder: $dotnetVersionPath..."
        try {
            Remove-Item -Path $dotnetVersionPath -Recurse -Force -ErrorAction Stop
            Write-Output "Folder deleted successfully: $dotnetVersionPath"
        } catch {
            Write-Error "Failed to delete folder: $dotnetVersionPath. Error: $_"
        }
    } else {
        Write-Output "Folder does not exist: $dotnetVersionPath"
    }
}

# Run the script
Stop-ProcessesUsingDotNet
Remove-DotNetFolder

Write-Output "Script completed. Ensure no traces of .NET Core 6.0.36 remain."


#pstanczyk 2024-11-22
