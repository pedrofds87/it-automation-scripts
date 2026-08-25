# Script: Remove ASPNET Core (8.0.12)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 183

# Path to the ASP.NET Core runtime folder
$targetPath = "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\8.0.12"

# Check if the folder exists
if (Test-Path $targetPath) {
    try {
        Write-Host "Stopping any running .NET processes..." -ForegroundColor Cyan
        Get-Process dotnet -ErrorAction SilentlyContinue | Stop-Process -Force

        Write-Host "Removing old ASP.NET Core runtime version at $targetPath..." -ForegroundColor Yellow
        Remove-Item -LiteralPath $targetPath -Recurse -Force

        Write-Host "' Successfully removed Microsoft.AspNetCore.App version 8.0.12." -ForegroundColor Green
    }
    catch {
        Write-Host "&��  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "The specified path does not exist: $targetPath" -ForegroundColor Gray
}
