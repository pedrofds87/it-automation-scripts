# Script: Stop sap business one server tools
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 203

Stop-Service -Name "B1ServerTools64" -Force

$service = Get-Service -Name "B1ServerTools64" -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Output "Service B1ServerTools64 not found"
} else {
    Write-Output "Service: $($service.Name)"
    Write-Output "Status : $($service.Status)"
    Write-Output "Startup: $($service.StartType)"
}
``