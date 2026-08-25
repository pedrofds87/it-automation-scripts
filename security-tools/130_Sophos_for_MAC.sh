# Script: Sophos for MAC
# Platform: Mac
# Description: #pstanczyk
# NinjaOne Script ID: 130

#!/bin/zsh

set -e

SOPHOS_DIR=$(mktemp -d -t Sophos_Install)
trap 'rm -rf "${SOPHOS_DIR}"' EXIT

ZIP_URL="https://api-cloudstation-us-east-2.prod.hydra.sophos.com/api/download/e03008de4161bfd1ec2300847f927b0d/SophosInstall.zip"
ZIP_FILE="${SOPHOS_DIR}/SophosInstall.zip"
LOG_FILE="/Library/Logs/SophosIntuneInstall.log"

echo "Starting Sophos install..." | tee -a "$LOG_FILE"
echo "Working directory: $SOPHOS_DIR" | tee -a "$LOG_FILE"

cd "$SOPHOS_DIR"

echo "Downloading Sophos installer..." | tee -a "$LOG_FILE"
curl -L "$ZIP_URL" -o "$ZIP_FILE"

if [ ! -f "$ZIP_FILE" ]; then
    echo "Download failed: SophosInstall.zip not found." | tee -a "$LOG_FILE"
    exit 1
fi

echo "Unzipping installer..." | tee -a "$LOG_FILE"
unzip -o "$ZIP_FILE" -d "$SOPHOS_DIR"

APP_PATH="${SOPHOS_DIR}/Sophos Installer.app"
BIN_PATH="${APP_PATH}/Contents/MacOS/Sophos Installer"
HELPER_PATH="${APP_PATH}/Contents/MacOS/tools/com.sophos.bootstrap.helper"

if [ ! -d "$APP_PATH" ]; then
    echo "Sophos Installer.app not found after unzip." | tee -a "$LOG_FILE"
    exit 1
fi

chmod a+x "$BIN_PATH"
chmod a+x "$HELPER_PATH"

echo "Running Sophos installer quietly..." | tee -a "$LOG_FILE"
"$BIN_PATH" --quiet

echo "Sophos installation command completed." | tee -a "$LOG_FILE"
exit 0