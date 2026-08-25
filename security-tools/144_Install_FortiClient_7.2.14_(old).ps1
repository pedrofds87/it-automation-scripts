# Script: Install FortiClient 7.2.14 (old)
# Platform: Windows
# Description: #pstanczyk 2026-03-16
# NinjaOne Script ID: 144

$FortiClientInstallerPath = "C:\Users\Public\Deployment\FortiClientSetup_7.2.14.msi"
$LogPath = "C:\Users\Public\Deployment\FortiClientInstall.log"

if ([string]::IsNullOrWhiteSpace($FortiClientInstallerPath)) {
    Write-Output "ERROR: Installer path variable is empty/null."
    exit 1
}

if (Test-Path -LiteralPath $FortiClientInstallerPath) {
    Write-Output "Installer found: $FortiClientInstallerPath"

    try {
        $args = "/i `"$FortiClientInstallerPath`" /qn /norestart /L*v `"$LogPath`""
        $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -PassThru
        Write-Output "Exit code: $($proc.ExitCode)"
        exit $proc.ExitCode
    }
    catch {
        Write-Output "ERROR: Install failed. $_"
        exit 1
    }
}
else {
    Write-Output "ERROR: Installer not found at: $FortiClientInstallerPath"
    exit 1
}