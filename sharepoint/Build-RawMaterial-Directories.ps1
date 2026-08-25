Write-Host "Loading Excel..."

$rows = Import-Excel "C:\Temp\RAW Inventory Details.xlsx"

Write-Host "Loading RA libraries..."

$RALibraries = Get-PnPList |
Where-Object {
    $_.BaseTemplate -eq 101 -and
    $_.Hidden -eq $false -and
    $_.Title -match '^RA-\d+'
}

foreach ($lib in $RALibraries)
{
    $itemNo = ([regex]::

    $row = $rows |
    Where-Object { $_.'Item No.' -eq $itemNo } |
    Select-Object -First 1

    ifll -eq $row)
    {
        continue
    }

    $existing = Get-PnPListItem -List "RA Directory" |
    Where-Object { $_["ItemNo"] -eq $itemNo }

    if ($existing)
    {
        Write-Host "Skipping $itemNo"
        continue
    }

    Add-PnPListItem -List "RA Directory" -Values @{
        "Title"       = $itemNo
        "ItemNo"      = $itemNo
        "Description" = $row.ItemDescription
        "Supplier"    = $row.SupplierName
        "LibraryUrl"  = "$($lib.DefaultViewUrl),Open Library"
    }

    Write-Host "Added $itemNo"
}

Write-Host "Finished"