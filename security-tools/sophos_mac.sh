#!/bin/zsh
# Script: Install Sophos Endpoint (macOS)
# Platform: macOS
# Description: Downloads SophosInstall.zip from Sophos Central and installs the endpoint agent.
# Deploy via: Microsoft Intune (Shell script, run as root)
# NOTE: ZIP_URL is unique per Sophos Central tenant — regenerate from:
#       Sophos Central > Endpoint Protection > Protect Devices > Download Installer (macOS)

#############################
# CONFIGURATION — update ZIP_URL from your Sophos Central portal
#############################
ZIP_URL="YOUR_SOPHOS_CENTRAL_INSTALLER_URL"
#############################

ZIP_PATH="/tmp/SophosInstall.zip"
EXTRACT_DIR="/tmp/SophosInstall"

echo "Downloading Sophos installer..."
curl -L -o "$ZIP_PATH" "$ZIP_URL"

if [ ! -f "$ZIP_PATH" ]; then
    echo "ERROR: Download failed."
    exit 1
fi

echo "Extracting installer..."
mkdir -p "$EXTRACT_DIR"
unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"

echo "Running Sophos installer..."
INSTALLER=$(find "$EXTRACT_DIR" -name "SophosInstall.app" -maxdepth 2 | head -1)

if [ -z "$INSTALLER" ]; then
    echo "ERROR: SophosInstall.app not found in zip."
    exit 1
fi

sudo "$INSTALLER/Contents/MacOS/SophosInstall" --quiet

echo "Cleaning up..."
rm -rf "$ZIP_PATH" "$EXTRACT_DIR"

echo "Sophos Endpoint installation complete."
