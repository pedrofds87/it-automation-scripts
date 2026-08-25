# Install-Sophos.ps1
# Download and silently install Sophos Endpoint via Sophos cloud link

$ErrorActionPreference = 'Stop'

# Sophos download URL
$DownloadUrl  = "https://api-cloudstation-us-east-2.prod.hydra.sophos.com/api/download/ef31545ad98202fa38b86143a7a31ecd/SophosSetup.exe"
$InstallerPath = Join-Path $env:TEMP "SophosSetup.exe"

Write-Output "Sophos Intune install script starting..."

# 1) Skip if Sophos already installed
$existingPath = "C:\Program Files\Sophos\Sophos Endpoint Agent"
if (Test-Path $existingPath) {
    Write-Output "Sophos appears to be already installed at '$existingPath'. Exiting."
    exit 0
}

try {
    # 2) Make sure TLS 1.2+ is used
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    } catch {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    # 3) Download the installer
    Write-Output "Downloading Sophos installer from $DownloadUrl ..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -Headers @{ 'User-Agent' = 'Mozilla/5.0' }

    if (-not (Test-Path $InstallerPath)) {
        throw "Download failed: file not found at $InstallerPath"
    }

    Write-Output "Download completed. Running the installer silently..."
    $proc = Start-Process -FilePath $InstallerPath -ArgumentList "--quiet" -Wait -PassThru

    Write-Output "Sophos installer exit code: $($proc.ExitCode)"

    if ($proc.ExitCode -ne 0) {
        throw "Sophos installer returned non-zero exit code: $($proc.ExitCode)"
    }

    # 4) Basic post-check
    if (-not (Test-Path $existingPath)) {
        throw "Sophos install path not found after install: $existingPath"
    }

    Write-Output "Sophos installation completed successfully."

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Test-Path $InstallerPath) {
        Write-Output "Cleaning up installer file..."
        Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue
    }
}

exit 0
