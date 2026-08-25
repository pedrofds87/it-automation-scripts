#!/bin/zsh
# Script: Install FortiClient 7.2.x (macOS)
# Platform: macOS
# Description: Downloads FortiClient 7.2.14 from an internal distribution server and installs it silently.
# Deploy via: Microsoft Intune (Shell script, run as root)
# NOTE: DOWNLOAD_URL points to an internal server — device must be on-network or connected via VPN.

#############################
# CONFIGURATION
#############################
# Update this URL to match your internal distribution server / FortiClient version
DOWNLOAD_URL="https://your-internal-server/installers/Default/FortiClient_7_2_x/FortiClient_7.2.14.dmg"
#############################

DMG_PATH="/tmp/FortiClient.dmg"
APP_NAME="FortiClient"

echo "Downloading FortiClient..."
curl -L -k -o "$DMG_PATH" "$DOWNLOAD_URL"

if [ ! -f "$DMG_PATH" ]; then
    echo "ERROR: Download failed. Check that the device can reach the distribution server."
    exit 1
fi

echo "Mounting DMG..."
hdiutil attach "$DMG_PATH" -nobrowse -quiet

VOLUME=$(ls /Volumes | grep -i "FortiClient" | head -1)

if [ -z "$VOLUME" ]; then
    echo "ERROR: Could not find FortiClient volume after mounting."
    hdiutil detach "/Volumes/$VOLUME" -quiet 2>/dev/null
    exit 1
fi

echo "Installing FortiClient..."
# Try .pkg installer first, fall back to .app copy
if ls "/Volumes/$VOLUME"/*.pkg &>/dev/null; then
    sudo installer -pkg "/Volumes/$VOLUME/"*.pkg -target /
else
    sudo cp -R "/Volumes/$VOLUME/$APP_NAME.app" /Applications/
fi

echo "Detaching DMG..."
hdiutil detach "/Volumes/$VOLUME" -quiet

echo "Cleaning up..."
rm -f "$DMG_PATH"

echo "FortiClient installation complete."
