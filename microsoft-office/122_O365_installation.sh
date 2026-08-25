# Script: O365 installation
# Platform: Mac
# Description: #pstanczyk 2024-11-08
# NinjaOne Script ID: 122

#!/bin/bash

# Define variables
INSTALLER_URL="https://go.microsoft.com/fwlink/?linkid=525133" # Official Microsoft 365 installer URL
INSTALLER_PATH="/tmp/Microsoft_Office_Installer.pkg"
LOG_FILE="/tmp/o365_installation.log"

echo "Starting Microsoft 365 installation..." | tee -a "$LOG_FILE"

# Close any running Microsoft Office applications
echo "Closing any running Microsoft Office applications..." | tee -a "$LOG_FILE"
osascript -e 'quit app "Microsoft Word"' 2>/dev/null
osascript -e 'quit app "Microsoft Excel"' 2>/dev/null
osascript -e 'quit app "Microsoft PowerPoint"' 2>/dev/null
osascript -e 'quit app "Microsoft Outlook"' 2>/dev/null

# Download the installer
echo "Downloading Microsoft 365 installer..." | tee -a "$LOG_FILE"
curl -L -o "$INSTALLER_PATH" "$INSTALLER_URL"
if [[ $? -ne 0 ]]; then
    echo "Failed to download the Microsoft 365 installer. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

# Install Microsoft 365
echo "Installing Microsoft 365..." | tee -a "$LOG_FILE"
sudo installer -pkg "$INSTALLER_PATH" -target /
if [[ $? -ne 0 ]]; then
    echo "Microsoft 365 installation failed. Please check the log for details." | tee -a "$LOG_FILE"
    exit 1
fi

# Clean up
echo "Cleaning up installer file..." | tee -a "$LOG_FILE"
rm -f "$INSTALLER_PATH"

echo "Microsoft 365 installation completed successfully." | tee -a "$LOG_FILE"

#pstanczyk 2024-11-08