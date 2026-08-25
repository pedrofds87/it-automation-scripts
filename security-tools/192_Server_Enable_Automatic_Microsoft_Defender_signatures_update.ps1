# Script: Server Enable Automatic Microsoft Defender signatures update
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 192

Set-MpPreference -SignatureUpdateCatchupInterval 4
Set-MpPreference -SignatureScheduleDay Everyday
Set-MpPreference -SignatureScheduleTime 01:00:00
