# Script: Slack using winget Windows
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 74

# Install or upgrade Slack
winget install --id=SlackTechnologies.Slack -e --accept-source-agreements

# Check the installed version
winget list --id=SlackTechnologies.Slack
