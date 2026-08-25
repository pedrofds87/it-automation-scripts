# Script: Remove .NET Core (8.0.12)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 182

# Path to the .NET runtime folder
$targetPath = "C:\Program Files\dotnet\shared\Microsoft.NetCore.App\8.0.12"

# Check if the folder exists
if (Test-Path $targetPath) {
    try {
        Write-Host "Stopping any running .NET processes..." -ForegroundColor Cyan
        Get-Process dotnet -ErrorAction SilentlyContinue | Stop-Process -Force

        Write-Host "Removing old .NET runtime version at $targetPath..." -ForegroundColor Yellow
        Remove-Item -LiteralPath $targetPath -Recurse -Force

        Write-Host "' Successfully removed Microsoft.NetCore.App version 8.0.12." -ForegroundColor Green
    }
    catch {
        Write-Host "&��  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "The specified path does not exist: $targetPath" -ForegroundColor Gray
}
