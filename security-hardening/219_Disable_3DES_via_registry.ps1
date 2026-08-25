# Script: Disable 3DES via registry
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 219

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168" `
-Name "Enabled" -Value 0 -PropertyType DWORD -Force | Out-Null

Write-Host "3DES disabled. Reboot required." -ForegroundColor Green