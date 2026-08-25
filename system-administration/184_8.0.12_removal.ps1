# Script: 8.0.12 removal
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 184

# Run as Administrator. Closes dotnet processes, uninstalls 8.0.12 packages via winget,
# verifies, and reports status.

$targets = @(
  @{ Id="Microsoft.DotNet.AspNetCore.8";  Version="8.0.12"; Friendly="ASP.NET Core 8.0.12" },
  @{ Id="Microsoft.DotNet.DesktopRuntime.8"; Version="8.0.12"; Friendly="Desktop Runtime 8.0.12" }
)

Write-Host "Stopping dotnet processes..." -ForegroundColor Cyan
Get-Process dotnet -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

foreach ($t in $targets) {
  $present = (winget list --id $t.Id 2>$null | Select-String -SimpleMatch $t.Version)
  if ($present) {
    Write-Host "Uninstalling $($t.Friendly)..." -ForegroundColor Yellow
    winget uninstall --id $($t.Id) --version $($t.Version) --silent `
      --accept-source-agreements --accept-package-agreements | Out-Null
  } else {
    Write-Host "$($t.Friendly) not listed by winget; skipping." -ForegroundColor DarkGray
  }
}

Start-Sleep -Seconds 3
Write-Host "`nVerification:" -ForegroundColor Cyan
$aspnet12  = (winget list --id Microsoft.DotNet.AspNetCore.8 2>$null | Select-String -SimpleMatch "8.0.12")
$desktop12 = (winget list --id Microsoft.DotNet.DesktopRuntime.8 2>$null | Select-String -SimpleMatch "8.0.12")
$runtimes  = dotnet --list-runtimes

if (-not $aspnet12 -and -not $desktop12) {
  Write-Host "' 8.0.12 packages removed." -ForegroundColor Green
} else {
  Write-Warning "8.0.12 still listed. A reboot may be required, or the entry may be part of another bundle."
}

Write-Host "`nInstalled runtimes:" -ForegroundColor Cyan
$runtimes | ForEach-Object { $_ }
