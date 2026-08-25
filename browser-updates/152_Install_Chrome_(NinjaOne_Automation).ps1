# Script: Install Chrome (NinjaOne Automation)
# Platform: Windows
# Description: pstanczyk
# NinjaOne Script ID: 152

param(
    $ChromeTimestampField = "chromeInstallationTimestamp"
)

$Path = "$env:TEMP\chrome_installer.exe"
$Url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
Invoke-WebRequest -Uri $Url -OutFile $Path
$process = Start-Process -FilePath $Path -Args '/silent /install' -NoNewWindow -Wait -PassThru
Remove-Item -Path $Path -Force

# Check if the installation was successful
if ($process.ExitCode -eq 0) {
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"  # ISO 8601 format for datetime
    # Update the custom field in NinjaOne with the timestamp
    Ninja-Property-Set $ChromeTimestampField $timestamp
    Write-Output "Action: Install Google Chrome, Result: Success, Time: $timestamp"
} else {
    Write-Output "Action: Install Google Chrome, Result: Failed, Exit Code: $($process.ExitCode)"
}
