# Script: remove .net 8.0.12 (use this one)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 191

# remove 8.0.12
dotnet --list-runtimes
Remove-Item -Recurse -Force "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\8.0.12"
Remove-Item -Recurse -Force "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\8.0.12"
dotnet --list-runtimes
