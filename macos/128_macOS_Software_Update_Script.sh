# Script: macOS Software Update Script
# Platform: Mac
# Description: #pstanczyk 2024-11-12
# NinjaOne Script ID: 128

#!/bin/bash

# Script to check for, install macOS updates, and display results

echo "Checking for macOS updates..."
softwareupdate -l

# Check if updates are available
updates_available=$(softwareupdate -l 2>&1 | grep -i "No new software available")

if [[ -z "$updates_available" ]]; then
  echo "Updates found. Installing..."
  
  # Install all updates and agree to the license automatically
  sudo softwareupdate -ia --verbose
  
  if [[ $? -eq 0 ]]; then
    echo "Updates installed successfully. Verifying..."
    softwareupdate -l
  else
    echo "There was an issue installing the updates. Please check the system logs for more details."
  fi
else
  echo "No updates available. System is up-to-date."
fi

#pstanczyk 2024-11-12