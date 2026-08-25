# Script: remove myDell files
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 201

$target = "C:\Program Files\Dell\MyDell"

# 1) Stop common Dell/MyDell/UCA processes (ignore if not running)
Get-Process -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match 'Dell|MyDell|UCA|Optimizer|SupportAssist' } |
  Stop-Process -Force -ErrorAction SilentlyContinue

# 2) Stop Dell-related services that might lock files (ignore if not present)
Get-Service -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match 'Dell|MyDell|Optimizer|SupportAssist|UCA' } |
  ForEach-Object { try { Stop-Service $_.Name -Force -ErrorAction SilentlyContinue } catch {} }

# 3) Take ownership + grant Administrators full control (recursively)
takeown /F "$target" /R /D Y
icacls "$target" /grant Administrators:(OI)(CI)F /T /C

# 4) Remove folder (force)
Remove-Item -LiteralPath "$target" -Recurse -Force
