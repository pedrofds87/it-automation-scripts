# Script: sleep and screen off to Never
# Platform: Windows
# Description: #pstanczyk 2024-12-03
# NinjaOne Script ID: 141

# Set display timeout to never (0 minutes)
Write-Output "Setting 'Turn off display' timeout to Never..."
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0

# Set sleep timeout to never (0 minutes)
Write-Output "Setting 'Sleep' timeout to Never..."
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

# Verify the settings
Write-Output "Verifying settings..."
powercfg /query | Select-String "monitor-timeout" -Context 0,1
powercfg /query | Select-String "standby-timeout" -Context 0,1

Write-Output "Power settings have been updated to 'Never' for both plugged in and on battery."



#pstanczyk 2024-12-03