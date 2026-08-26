# Script: Install DUO for Windows
# Platform: Windows
# Description: #pstanczyk 2024-12-05
# NinjaOne Script ID: 146
# Get IKEY, SKEY, and HOST from: Duo Admin Panel > Applications > Microsoft RDP


# Define the download URL and installer path
$DuoUrl = "https://dl.duosecurity.com/duo-win-login-latest.exe"
$DuoInstallerPath = "C:\Users\Public\duo-win-login-latest.exe"


# Define Duo parameters
$IKEY = "YOUR_DUO_INTEGRATION_KEY"    # Integration key (starts with DI...)
$SKEY = "YOUR_DUO_SECRET_KEY"         # Secret key
$DuoHost = "YOUR_DUO_API_HOSTNAME"    # e.g. api-xxxxxxxx.duosecurity.com


# Duo installation options
$DuoArguments = @"
/S /V` /qn IKEY=`"$IKEY`" SKEY=`"$SKEY`" HOST=`"$DuoHost`" AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#0 RDPONLY=#0 UAC_PROTECTMODE=#2`"
"@


# Download the Duo installer
Write-Output "Downloading Duo installer..."
Invoke-WebRequest -Uri $DuoUrl -OutFile $DuoInstallerPath


# Verify the installer exists
if (Test-Path $DuoInstallerPath) {
    Write-Output "Duo installer downloaded successfully. Starting installation..."
    
    # Run the Duo installer with parameters
    Start-Process -FilePath $DuoInstallerPath -ArgumentList $DuoArguments -Wait -NoNewWindow
    Write-Output "Duo installation complete."
} else {
    Write-Output "ERROR: Duo installer not found. Download may have failed."
    exit 1
}
