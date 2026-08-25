# Script: smb configuration
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 221

Set-SmbServerConfiguration -EnableSecuritySignature $true -RequireSecuritySignature $true -Force