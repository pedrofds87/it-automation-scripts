# Script: check if B1ServerTools64 is running on .83
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 227

$service = Get-Service -Name "B1ServerTools64" -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Output "Service B1ServerTools64 not found"
}
else {
    Write-Output "Service: $($service.Name)"
    Write-Output "Status : $($service.Status)"
    Write-Output "Startup: $($service.StartType)"
}
