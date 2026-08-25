# Script: Terminal server register add
# Platform: Windows
# Description: pstanczyk
# NinjaOne Script ID: 155

reg add "HKLM\software\policies\microsoft\windows nt\Terminal Services\Client" /v fClientDisableUDP /d 1 /t REG_DWORD