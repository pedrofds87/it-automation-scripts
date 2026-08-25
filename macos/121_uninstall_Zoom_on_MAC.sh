# Script: uninstall Zoom on MAC
# Platform: Mac
# Description: #pstanczyk
# NinjaOne Script ID: 121

#!/bin/bash

# Define Zoom app paths
ZOOM_APP_PATH="/Applications/zoom.us.app"
ZOOM_SUPPORT_PATH="$HOME/Library/Application Support/zoom.us"
ZOOM_PREFERENCES_PATH="$HOME/Library/Preferences/us.zoom.xos.plist"
ZOOM_CACHES_PATH="$HOME/Library/Caches/us.zoom.xos"
ZOOM_LOGS_PATH="$HOME/Library/Logs/zoom.us"

echo "Starting Zoom uninstallation process..."

# Quit Zoom if it is running
if pgrep -x "zoom.us" > /dev/null; then
    echo "Zoom is currently running. Closing Zoom..."
    osascript -e 'quit app "zoom.us"'
    sleep 2
fi

# Remove Zoom application
if [ -d "$ZOOM_APP_PATH" ]; then
    echo "Removing Zoom application..."
    sudo rm -rf "$ZOOM_APP_PATH"
fi

# Remove Zoom support files
echo "Removing Zoom support files..."
rm -rf "$ZOOM_SUPPORT_PATH" "$ZOOM_PREFERENCES_PATH" "$ZOOM_CACHES_PATH" "$ZOOM_LOGS_PATH"

echo "Zoom has been uninstalled successfully."

#pstanczyk