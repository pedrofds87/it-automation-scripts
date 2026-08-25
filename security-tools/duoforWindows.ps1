# Script: Install Duo Authentication for Windows Logon
# Platform: Windows
# Description: Downloads and silently installs Duo Windows Logon with configurable integration key and host.
# Deploy via: NinjaOne RMM or Microsoft Intune
# Duo docs: https://duo.com/docs/winlogon

#############################
# CONFIGURATION — fill in before deploying
# Get IKEY, SKEY, and HOST from: Duo Admin Panel > Applications > Microsoft RDP
#############################
$IKEY    = "YOUR_DUO_INTEGRATION_KEY"    # Integration key (starts with DI...)
$SKEY    = "YOUR_DUO_SECRET_KEY"         # Secret key
$DuoHost = "YOUR_DUO_API_HOSTNAME"       # e.g. api-xxxxxxxx.duosecurity.com
#############################

# Define the download URL and installer path
$DuoUrl           = "https://dl.duosecurity.com/duo-win-login-latest.exe"
$DuoInstallerPath = "C:\Users\Public\duo-win-login-latest.exe"

# Duo installation options
$DuoArguments = @"
/S /V" /qn IKEY="$IKEY" SKEY="$SKEY" HOST="$DuoHost" AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#0 RDPONLY=#0 UAC_PROTECTMODE=#2"
"@

# Download the Duo installer
Write-Output "Downloading Duo installer..."
Invoke-WebRequest -Uri $DuoUrl -OutFile $DuoInstallerPath

# Verify the installer exists
if (Test-Path $DuoInstallerPath) {
    Write-Output "Duo installer downloaded successfully. Starting installation..."

    # Run the Duo installer with parameters
    Start-Process -FilePath $DuoInstallerPath -ArgumentList $DuoArguments -Wait -NoNewWindow

    Write-Output "Duo installation completed successfully."

    # Verify installation by checking registry
    Write-Output "Verifying Duo settings in the registry..."
    Get-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" | Format-List

    # Clean up
    Write-Output "Cleaning up Duo installer..."
    Remove-Item -Path $DuoInstallerPath -Force
} else {
    Write-Output "Error: Failed to download the Duo installer."
}

# pstanczyk 2024-12-05
