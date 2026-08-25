# Script: chrome update for MacBook
# Platform: Mac
# Description: #pstanczyk
# NinjaOne Script ID: 185

#!/bin/bash
set -euo pipefail

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

CHROME_APP="/Applications/Google Chrome.app"
DMG="/tmp/googlechrome.dmg"
VOL="/Volumes/ChromeUpdate.$$"   # unique, predictable mount point

# Get current version (if installed)
before="unknown"
if [ -d "$CHROME_APP" ]; then
  before=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
    "$CHROME_APP/Contents/Info.plist" 2>/dev/null || echo "unknown")
fi

log "Closing all Chrome processes..."
pkill -f "Google Chrome" 2>/dev/null || true
sleep 2

# Fetch universal DMG (this endpoint works across Intel/Apple Silicon)
URL="https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
rm -f "$DMG"
log "Downloading Chrome DMG &"
if ! /usr/bin/curl -L --fail --retry 3 -o "$DMG" "$URL"; then
  log "ERROR: download failed."
  exit 1
fi

# Sanity check (must be >5MB)
size=$(stat -f%z "$DMG" 2>/dev/null || echo 0)
if [ "$size" -le 5000000 ]; then
  log "ERROR: DMG too small (${size} bytes)   likely a bad redirect."
  exit 1
fi
log "DMG downloaded (${size} bytes)."

# Mount to known mount point (no parsing of hdiutil output)
log "Mounting DMG to $VOL  &"
mkdir -p "$VOL"
# Use -nobrowse and explicit -mountpoint; don't suppress output to keep errors visible
hdiutil attach "$DMG" -nobrowse -mountpoint "$VOL"
trap 'hdiutil detach "$VOL" -quiet || true' EXIT

# Verify app exists on mounted volume
if [ ! -d "$VOL/Google Chrome.app" ]; then
  log "ERROR: Google Chrome.app not found on mounted volume."
  exit 1
fi

# Install/overwrite to /Applications
log "Installing to /Applications  &"
/usr/bin/ditto -V "$VOL/Google Chrome.app" "$CHROME_APP"

# Clear quarantine just in case
xattr -dr com.apple.quarantine "$CHROME_APP" 2>/dev/null || true

# Unmount
log "Unmounting DMG &"
hdiutil detach "$VOL" -quiet || true
trap - EXIT
rm -f "$DMG"

# Reopen Chrome
log "Reopening Google Chrome &"
open -a "Google Chrome"

sleep 2
after=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
  "$CHROME_APP/Contents/Info.plist" 2>/dev/null || echo "unknown")

log "Chrome version before: $before"
log "Chrome version now:    $after"
log "Done."
