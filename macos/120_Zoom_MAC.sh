# Script: Zoom MAC
# Platform: Mac
# Description: #pstanczyk
# NinjaOne Script ID: 120

#!/bin/bash

# Define the Zoom download URL
ZOOM_URL="https://cdn.zoom.us/prod/5.13.3.11001/Zoom.pkg"
ZOOM_PKG="$HOME/Downloads/Zoom.pkg"

# Ensure the Downloads directory exists
mkdir -p "$HOME/Downloads"

# Download Zoom package
echo "Downloading Zoom..."
curl -L -o "$ZOOM_PKG" "$ZOOM_URL"
if [[ $? -ne 0 ]]; then
    echo "Failed to download Zoom package. Please check your internet connection or the download URL."
    exit 1
fi

# Install Zoom
echo "Installing Zoom..."
sudo installer -pkg "$ZOOM_PKG" -target /
if [[ $? -ne 0 ]]; then
    echo "Failed to install Zoom."
    exit 1
fi

# Cleanup
rm "$ZOOM_PKG"
echo "Zoom has been updated to the latest version."
