# Script: macOS update 
# Platform: Mac
# Description: #pstanczyk
# NinjaOne Script ID: 207

#!/bin/bash

echo "Checking for updates..."
updates=$(softwareupdate -l)

echo "$updates"

echo "Installing available updates..."
softwareupdate --install --all --restart --force


if softwareupdate -l | grep -q "restart"; then
    echo "Reboot required. Restarting in 5 minutes..."
    shutdown -r +5
else
    echo "No reboot required."
fi
