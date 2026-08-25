# Script: Start Azure AD services on 100.3
# Platform: Windows
# Description: #pstanczyk strat after restart the server
# NinjaOne Script ID: 212

$services = @(
    "AzureADConnectAgentUpdater",
    "ADSync"
)

foreach ($service in $services) {

    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue

    if ($svc.Status -ne "Running") {
        Write-Host "$service is not running. Starting it..."
        Start-Service -Name $service
        Write-Host "$service started."
    }
    else {
        Write-Host "$service is already running."
    }

}