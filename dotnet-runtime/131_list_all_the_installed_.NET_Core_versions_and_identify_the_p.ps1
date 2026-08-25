# Script: list all the installed .NET Core versions and identify the processes using each version
# Platform: Windows
# Description: #pstanczyk 2024-11-19
# NinjaOne Script ID: 131

# Define the base path where .NET Core versions are installed
$dotnetBasePath = "C:\Program Files\dotnet\shared\Microsoft.NetCore.App"

# Check if the base path exists
if (Test-Path $dotnetBasePath) {
    Write-Output "Checking installed .NET Core versions..."
    
    # Get all installed versions
    $versions = Get-ChildItem -Path $dotnetBasePath | Where-Object { $_.PSIsContainer }

    if ($versions.Count -eq 0) {
        Write-Output "No .NET Core versions found in $dotnetBasePath."
    } else {
        Write-Output "Found the following installed .NET Core versions:"
        $versions.FullName | ForEach-Object { Write-Output $_ }

        # Check processes using each version
        foreach ($version in $versions) {
            $versionPath = $version.FullName

            Write-Output "`nChecking processes using .NET Core version at: ${versionPath}..."

            # Find processes using this .NET Core version
            $processes = Get-Process | Where-Object {
                $_.Modules | Where-Object { $_.FileName -like "${versionPath}\*" }
            }

            if ($processes) {
                Write-Output "Processes using ${versionPath}:"
                $processes | ForEach-Object {
                    Write-Output "Process Name: $($_.ProcessName), ID: $($_.Id)"
                }
            } else {
                Write-Output "No processes are currently using ${versionPath}."
            }
        }
    }
} else {
    Write-Output "The specified path for .NET Core installations does not exist: $dotnetBasePath."
}


#pstanczyk 2024-11-19