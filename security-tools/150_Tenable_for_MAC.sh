# Script: Tenable for MAC
# Platform: Mac
# Description: pstanczyk
# NinjaOne Script ID: 150

#!/bin/zsh

set -euo pipefail

LOG_FILE="/Library/Logs/TenableNessusAgentIntuneInstall.log"
WORK_DIR="/private/var/tmp/TenableNessusAgent"
DMG_FILE="${WORK_DIR}/NessusAgent.dmg"

DOWNLOAD_URL="https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/28556/download?i_agree_to_tenable_license_agreement=true"

LINK_KEY="cbda26ae4c08a6a91fb547497aaab6ee5e0f18bee5057fc24f7a6006ba851a1e"
HOST="cloud.tenable.com"
PORT="443"
GROUPS="Laptop"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========== Tenable Nessus Agent Intune Install =========="
date

mkdir -p "$WORK_DIR"

if [ -x "/Library/NessusAgent/run/sbin/nessuscli" ]; then
    echo "Nessus Agent already installed."
    /Library/NessusAgent/run/sbin/nessuscli agent status || true
    exit 0
fi

echo "Downloading DMG..."
curl -L --fail --retry 3 --connect-timeout 30 "$DOWNLOAD_URL" -o "$DMG_FILE"

if [ ! -f "$DMG_FILE" ]; then
    echo "ERROR: DMG download failed."
    exit 1
fi

echo "Downloaded file:"
ls -lh "$DMG_FILE"

echo "Verifying file type..."
file "$DMG_FILE" || true

echo "Checking DMG info..."
hdiutil imageinfo "$DMG_FILE" || true

echo "Mounting DMG..."
ATTACH_OUTPUT=$(hdiutil attach "$DMG_FILE" -nobrowse 2>&1)
ATTACH_EXIT=$?

echo "$ATTACH_OUTPUT"

if [ "$ATTACH_EXIT" -ne 0 ]; then
    echo "ERROR: hdiutil attach failed."
    exit 1
fi

MOUNT_POINT=$(echo "$ATTACH_OUTPUT" | sed -n 's|^.*\(/Volumes/.*\)$|\1|p' | tail -n 1)

if [ -z "${MOUNT_POINT:-}" ] || [ ! -d "$MOUNT_POINT" ]; then
    echo "ERROR: Could not determine DMG mount point."
    echo "Current mounted volumes:"
    ls -la /Volumes
    exit 1
fi

echo "Mounted at: $MOUNT_POINT"

echo "DMG contents:"
find "$MOUNT_POINT" -maxdepth 5 -print

echo "Searching for installer package..."
PKG_PATH=$(find "$MOUNT_POINT" -maxdepth 5 \( -iname "*.pkg" -o -iname "*.mpkg" \) | head -n 1)

if [ -z "${PKG_PATH:-}" ]; then
    echo "ERROR: No PKG or MPKG found inside DMG."
    hdiutil detach "$MOUNT_POINT" || true
    exit 1
fi

echo "Installing package: $PKG_PATH"
installer -pkg "$PKG_PATH" -target /

if [ ! -x "/Library/NessusAgent/run/sbin/nessuscli" ]; then
    echo "ERROR: Nessus Agent CLI not found after install."
    hdiutil detach "$MOUNT_POINT" || true
    exit 1
fi

echo "Linking Nessus Agent..."
/Library/NessusAgent/run/sbin/nessuscli agent link \
  --key="$LINK_KEY" \
  --host="$HOST" \
  --port="$PORT" \
  --groups="$GROUPS"

echo "Starting Nessus Agent service..."
launchctl kickstart -k system/com.tenablesecurity.nessusagent || true

echo "Checking agent status..."
/Library/NessusAgent/run/sbin/nessuscli agent status || true

echo "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" || true

echo "Cleaning up..."
rm -rf "$WORK_DIR"

echo "Tenable Nessus Agent installation completed."
exit 0