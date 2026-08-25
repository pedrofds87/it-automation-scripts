# ==============================
# SharePoint Bulk File Delete
# ==============================

#run before to get ClientId Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP PowerShell SharePoint Cleanup" -Tenant "iammutant.onmicrosoft.com"

# Requires PowerShell 7+
# Install first if needed:
# Install-Module PnP.PowerShell -Scope CurrentUser -Force

$SiteUrl = "https://iammutant.sharepoint.com/sites/Infra"
$Tenant = "iammutant.onmicrosoft.com"
$ClientId = "paste here"

$CsvPath = "C:\Temp\files-to-delete.csv"
$DryRun = $false

Import-Module PnP.PowerShell
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId -Tenant $Tenant

$Files = Import-Csv $CsvPath

foreach ($File in $Files) {
    $RelativePath = $File.'Full Path'.Trim()

    $ServerRelativeUrl = "/sites/Infra/Shared%20Documents/$RelativePath"
    $ServerRelativeUrl = $ServerRelativeUrl -replace " ", "%20"

    Write-Host "Deleting: $ServerRelativeUrl"

    Remove-PnPFile -ServerRelativeUrl $ServerRelativeUrl -Force -Recycle
}

Disconnect-PnPOnline
Write-Host "Done."