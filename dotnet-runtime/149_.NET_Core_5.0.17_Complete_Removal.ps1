# Script: .NET Core 5.0.17 Complete Removal
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 149

# Ensure the script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "Please run this script as Administrator."
    exit
}

# Define paths to remove
$DotNetPath = "C:\Program Files\dotnet\shared\Microsoft.NetCore.App\5.0.17"

# Uninstall using the built-in uninstaller if available
Write-Output "Uninstalling .NET Core Runtime 5.0.17..."
$UninstallString = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*Microsoft .NET*5.0*" }).UninstallString
if ($UninstallString) {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $UninstallString /quiet /norestart" -Wait
    Write-Output ".NET Core Runtime 5.0.17 uninstalled successfully."
} else {
    Write-Warning "Uninstaller for .NET Core Runtime 5.0.17 not found. Proceeding with manual cleanup."
}

# Remove residual files
Write-Output "Removing residual files..."
if (Test-Path $DotNetPath) {
    Remove-Item -Path $DotNetPath -Recurse -Force
    Write-Output "Removed: $DotNetPath"
} else {
    Write-Warning "Path not found: $DotNetPath"
}

# Clean registry entries
Write-Output "Cleaning up registry entries..."
$RegistryPaths = @(
    "HKLM:\Software\Microsoft\.NETCore\App",
    "HKLM:\Software\Microsoft\dotnet",
    "HKCU:\Software\Microsoft\.NETCore\App",
    "HKCU:\Software\Microsoft\dotnet"
)

foreach ($RegistryPath in $RegistryPaths) {
    if (Test-Path $RegistryPath) {
        Remove-Item -Path $RegistryPath -Recurse -Force
        Write-Output "Removed registry key: $RegistryPath"
    } else {
        Write-Warning "Registry path not found: $RegistryPath"
    }
}

Write-Output "Cleanup completed successfully."
