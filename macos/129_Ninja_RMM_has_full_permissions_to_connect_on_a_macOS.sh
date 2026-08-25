# Script: Ninja RMM has full permissions to connect on a macOS
# Platform: Mac
# Description: #pstanczyk 2024-11-12
# NinjaOne Script ID: 129

#!/bin/bash

# Script to grant full permissions to Ninja RMM on macOS

# Variables
APP_NAME="NinjaRMM"
BUNDLE_ID="com.ninjarmm.agent"
TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"

echo "Granting full permissions to $APP_NAME..."

# Check if Ninja RMM Agent is installed
if [ -d "/Applications/NinjaRMM.app" ] || [ -d "/Library/Ninja" ]; then
    echo "$APP_NAME detected. Configuring permissions..."

    # Grant Full Disk Access
    sqlite3 "$TCC_DB" "REPLACE INTO access VALUES('kTCCServiceAccessibility','${BUNDLE_ID}',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,0,1541440109);" 2>/dev/null
    sqlite3 "$TCC_DB" "REPLACE INTO access VALUES('kTCCServiceScreenCapture','${BUNDLE_ID}',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,0,1541440109);" 2>/dev/null

    # Grant System Events and Accessibility permissions
    sudo tccutil reset Accessibility $BUNDLE_ID
    sudo tccutil reset ScreenCapture $BUNDLE_ID
    sudo tccutil reset SystemPolicyAllFiles $BUNDLE_ID

    echo "Permissions granted for Full Disk Access, Screen Recording, and Accessibility."
else
    echo "$APP_NAME is not installed on this machine."
    exit 1
fi

# Restart the Ninja RMM agent to apply changes
echo "Restarting Ninja RMM Agent..."
launchctl unload /Library/LaunchDaemons/com.ninjarmm.agent.plist
launchctl load /Library/LaunchDaemons/com.ninjarmm.agent.plist

echo "Permissions successfully configured for $APP_NAME."

exit 0

#pstanczyk 2024-11-12