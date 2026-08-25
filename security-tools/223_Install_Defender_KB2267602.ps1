# Script: Install Defender KB2267602
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 223

# Installs PSWindowsUpdate if missing, then installs only KB2267602
# Run as Administrator

Write-Host "=== Install Defender KB2267602 ===" -ForegroundColor Cyan

# Ensure TLS 1.2 for PSGallery access on older systems
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

# Make script execution permissive for this session only
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
} catch {}

# Install PSWindowsUpdate if missing
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "PSWindowsUpdate module not found. Installing..." -ForegroundColor Yellow

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
} else {
    Write-Host "PSWindowsUpdate module already installed." -ForegroundColor Green
}

# Import module
Import-Module PSWindowsUpdate -Force

# Install only KB2267602
Write-Host "Searching for KB2267602..." -ForegroundColor Yellow
Get-WindowsUpdate -KBArticleID KB2267602 -Install -AcceptAll -IgnoreReboot -Verbose

Write-Host "=== Completed ===" -ForegroundColor Cyan