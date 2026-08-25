# Script: Force Microsoft Office Updates on macOS
# Platform: Mac
# Description: #pstanczyk 2024-11-07
# NinjaOne Script ID: 116

#!/bin/bash

# Define the minimum required version for Microsoft Office
REQUIRED_VERSION="16.81"

# Function to get the installed version of Office (using Word as an example)
get_office_version() {
  if [ -f "/Applications/Microsoft Word.app/Contents/Info.plist" ]; then
    /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "/Applications/Microsoft Word.app/Contents/Info.plist"
  else
    echo "Microsoft Office is not installed."
    exit 1
  fi
}

# Get the installed version of Office
INSTALLED_VERSION=$(get_office_version)
echo "Installed Office version: $INSTALLED_VERSION"
echo "Required version: $REQUIRED_VERSION"

# Function to run Microsoft AutoUpdate
run_autoupdate() {
  if [ -f "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" ]; then
    echo "Running Microsoft AutoUpdate..."
    "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --install
  else
    echo "Microsoft AutoUpdate tool not found. Launching AutoUpdate app..."
    open "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
  fi
}

# Compare versions using version sorting
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$INSTALLED_VERSION" | sort -V | head -n 1)" != "$REQUIRED_VERSION" ]; then
  echo "An update is required. Attempting to update..."
  run_autoupdate
else
  echo "Microsoft Office is up-to-date."
fi


#pstanczyk 2024-11-07