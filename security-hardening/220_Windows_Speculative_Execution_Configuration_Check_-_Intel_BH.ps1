# Script: Windows Speculative Execution Configuration Check - Intel BHI (CVE-2022-0001)
# Platform: Windows
# Description: Windows Speculative Execution Configuration Check - Intel BHI (CVE-2022-0001) #pstanczyk
# NinjaOne Script ID: 220

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name "FeatureSettingsOverride" -Value 0 -PropertyType DWORD -Force

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name "FeatureSettingsOverrideMask" -Value 3 -PropertyType DWORD -Force