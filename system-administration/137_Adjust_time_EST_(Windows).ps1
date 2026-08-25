# Script: Adjust time EST (Windows)
# Platform: Windows
# Description: #pstanczyk 2024-11-26
# NinjaOne Script ID: 137

# Define the NTP server
$NtpServer = "time.windows.com"

# Create a UDP client
$UdpClient = New-Object System.Net.Sockets.UdpClient
$UdpClient.Connect($NtpServer, 123)

# Create the NTP request packet
$NtpData = New-Object byte[] 48
$NtpData[0] = 0x1B

# Send the request
$UdpClient.Send($NtpData, $NtpData.Length)

# Receive the response
$RemoteEndPoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Any, 0)
$NtpData = $UdpClient.Receive([ref]$RemoteEndPoint)

# Extract the timestamp (offset 40 to 43)
$IntPart = [BitConverter]::ToUInt32($NtpData[43..40], 0)
$FracPart = [BitConverter]::ToUInt32($NtpData[47..44], 0)

# Convert to milliseconds
$Milliseconds = ($IntPart * 1000) + (($FracPart * 1000) / 0x100000000)

# Calculate the date and time
$NtpEpoch = (Get-Date "1900-01-01 00:00:00").AddMilliseconds($Milliseconds)

# Convert to local time
$UtcTime = $NtpEpoch.ToUniversalTime()

# Manually adjust for EST (UTC-5) or EDT (UTC-4)
# Assuming current time falls under standard EST offset:
$ESTOffset = -5  # Hours
$EstTime = $UtcTime.AddHours($ESTOffset)

# Display the result
Write-Output "Corrected Current EST Time: $EstTime"



#pstanczyk 2024-11-26