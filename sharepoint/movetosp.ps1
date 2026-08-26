$ErrorActionPreference = 'Stop'

# Connect using device code (avoids the popup/WAM issue)
Connect-MgGraph -Scopes "Sites.Read.All","Files.ReadWrite.All"

# SharePoint target
$siteId  = "YOUR-TENANT.sharepoint.com,YOUR-SITE-GUID,YOUR-WEB-GUID"
$driveId = "b!Tj11bX8lLECvaZ5FMAdX7LOipFwctcFBnzxAHY7eCM5akcFGThosTLbvDIYBPprj"

# Local file
$filePath = "C:\Path\To\Your\File.xlsx"

if (-not (Test-Path -LiteralPath $filePath)) {
    throw "Local file not found: $filePath"
}

$fileName = [System.IO.Path]::GetFileName($filePath)

# Upload to the root of the Documents library
$uri = ("https://graph.microsoft.com/v1.0/sites/{0}/drives/{1}/root:/{2}:/content" -f $siteId, $driveId, $fileName)

try {
    $bytes = [System.IO.File]::ReadAllBytes($filePath)

    $result = Invoke-MgGraphRequest `
        -Method PUT `
        -Uri $uri `
        -Body $bytes `
        -ContentType "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    Write-Host "✅ Upload successful" -ForegroundColor Green
    Write-Host ("File: " + $result.name)
    if ($result.webUrl) {
        Write-Host ("URL: " + $result.webUrl)
    }
}
catch {
    Write-Host "❌ Upload failed" -ForegroundColor Red
    Write-Host $_.Exception.Message
    throw
}
