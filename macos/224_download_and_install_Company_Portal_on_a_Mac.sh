# Script: download and install Company Portal on a Mac
# Platform: Mac
# Description: #pstanczyk
# NinjaOne Script ID: 224

#!/bin/bash

set -e

URL="https://aka.ms/EnrollMyMac"
PKG="/tmp/CompanyPortal-Installer.pkg"

echo "Downloading Intune Company Portal..."
curl -L "$URL" -o "$PKG"

echo "Installing Intune Company Portal..."
sudo installer -pkg "$PKG" -target /

echo "Cleaning up..."
rm -f "$PKG"

echo "Done. Company Portal is installed in /Applications."
echo "Next step: open Company Portal and sign in with the user's work account to complete Intune enrollment."