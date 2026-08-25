# Script: asp net removal toll
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 200

# Download + install dotnet-core-uninstall (MSI)

$ErrorActionPreference = "Stop"

$url      = "https://github.com/dotnet/cli-lab/releases/download/1.7.656206/dotnet-core-uninstall.msi"
$destDir  = Join-Path $env:ProgramData "DotNetCoreUninstall"
$msiPath  = Join-Path $destDir "dotnet-core-uninstall.msi"
$logPath  = Join-Path $destDir "install.log"

New-Item -ItemType Directory -Path $destDir -Force | Out-Null

Write-Host "Downloading MSI..."
Invoke-WebRequest -Uri $url -OutFile $msiPath -UseBasicParsing

if (-not (Test-Path $msiPath)) { throw "Download failed: $msiPath not found." }

Write-Host "Installing MSI silently..."
$arguments = "/i `"$msiPath`" /qn /norestart /L*v `"$logPath`""
$proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru

Write-Host "msiexec exit code: $($proc.ExitCode)"
Write-Host "Log: $logPath"

if ($proc.ExitCode -ne 0) {
    throw "MSI install failed with exit code $($proc.ExitCode). See log: $logPath"
}

Write-Host "Install completed successfully."
