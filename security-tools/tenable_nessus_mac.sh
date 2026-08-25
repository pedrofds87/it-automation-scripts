#!/bin/zsh
# Script: Install Tenable Nessus Agent (macOS)
# Platform: macOS
# Description: Downloads and installs the Tenable Nessus Agent, then links it to the Tenable cloud.
# Deploy via: Microsoft Intune (Shell script, run as root)

#############################
# CONFIGURATION — fill in before deploying
#############################
LINK_KEY="YOUR_TENABLE_LINK_KEY"       # From Tenable.io > Sensors > Nessus Agents > Agent Linking Keys
HOST="cloud.tenable.com"
PORT="443"
GROUPS="Laptop"
DOWNLOAD_URL="https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/28556/download?i_agree_to_tenable_license_agreement=true"
#############################

DMG_PATH="/tmp/NessusAgent.dmg"

echo "Downloading Nessus Agent..."
curl -L -o "$DMG_PATH" "$DOWNLOAD_URL"

echo "Mounting DMG..."
hdiutil attach "$DMG_PATH" -nobrowse -quiet

MOUNT_POINT=$(hdiutil info | grep "Nessus Agent" | awk '{print $1}')
VOLUME=$(ls /Volumes | grep -i "Nessus Agent" | head -1)

echo "Installing package..."
sudo installer -pkg "/Volumes/$VOLUME/Install Nessus Agent.pkg" -target /

echo "Detaching DMG..."
hdiutil detach "/Volumes/$VOLUME" -quiet

echo "Linking agent to Tenable cloud..."
sudo /Library/NessusAgent/run/sbin/nessuscli agent link \
    --key="$LINK_KEY" \
    --host="$HOST" \
    --port="$PORT" \
    --groups="$GROUPS"

echo "Starting Nessus Agent service..."
sudo launchctl load /Library/LaunchDaemons/com.tenablesecurity.nessusagent.plist 2>/dev/null || true
sudo /Library/NessusAgent/run/sbin/nessusd -D 2>/dev/null &

echo "Cleaning up..."
rm -f "$DMG_PATH"

echo "Nessus Agent installation complete."
