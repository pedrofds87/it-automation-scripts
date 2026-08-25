# Script: Install DUO for Windows
# Platform: Windows
# Description: #pstanczyk 2024-12-05
# NinjaOne Script ID: 146

# Define the download URL and installer path
$DuoUrl = "https://dl.duosecurity.com/duo-win-login-latest.exe"
$DuoInstallerPath = "C:\Users\Public\duo-win-login-latest.exe"

# Define Duo parameters
$IKEY = "DI1JWUTA5MX2N4AD0ZTJ"
$SKEY = "5HG5b06ZUUxd0UqZb6JKmZGvraFQWQSO89X9gRJM"
$DuoHost = "api-43e9879b.duosecurity.com"  # Renamed to $DuoHost to avoid conflict

# Duo installation options
$DuoArguments = @"
/S /V`" /qn IKEY=`"$IKEY`" SKEY=`"$SKEY`" HOST=`"$DuoHost`" AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#0 RDPONLY=#0 UAC_PROTECTMODE=#2`"
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


#pstanczyk 2024-12-05
