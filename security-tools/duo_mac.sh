#!/bin/zsh
# Script: Install Duo Authentication for macOS Logon
# Platform: macOS
# Description: Downloads and installs the Duo Authentication for macOS package, configured for your Duo tenant.
# Deploy via: Microsoft Intune (Shell script, run as root)
# Duo docs: https://duo.com/docs/macos

#############################
# CONFIGURATION — fill in before deploying
# Get IKEY, SKEY, and DUO_HOST from: Duo Admin Panel > Applications > macOS Logon
#############################
IKEY="YOUR_DUO_INTEGRATION_KEY"        # Integration key (starts with DI...)
SKEY="YOUR_DUO_SECRET_KEY"             # Secret key
DUO_HOST="YOUR_DUO_API_HOSTNAME"       # e.g. api-xxxxxxxx.duosecurity.com
#############################

PKG_URL="https://dl.duosecurity.com/duo-unix-latest.pkg"
PKG_PATH="/tmp/duo_macos.pkg"
PLIST_PATH="/etc/duo/login_duo.conf"

echo "Downloading Duo macOS package..."
curl -L -o "$PKG_PATH" "$PKG_URL"

if [ ! -f "$PKG_PATH" ]; then
    echo "ERROR: Download failed."
    exit 1
fi

echo "Installing Duo macOS package..."
sudo installer -pkg "$PKG_PATH" -target /

echo "Writing Duo configuration..."
sudo mkdir -p /etc/duo
sudo tee "$PLIST_PATH" > /dev/null <<EOF
[duo]
ikey = $IKEY
skey = $SKEY
host = $DUO_HOST
failmode = safe
autopush = yes
prompts = 1
EOF

sudo chmod 600 "$PLIST_PATH"

echo "Cleaning up..."
rm -f "$PKG_PATH"

echo "Duo macOS Logon installation complete."
