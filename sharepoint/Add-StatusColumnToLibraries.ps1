<#
.SYNOPSIS
    Moves the shared "Status" column (Approved / Inactive) off the individual RA-/FL-/WH-
    document libraries and onto the 3 directory lists instead (one Status per supplier row),
    then bulk-sets every existing supplier to "Approved".

.DESCRIPTION
    This corrects an earlier misunderstanding where Status was added to each of the 337
    individual libraries. The actual requirement is one Status value per SUPPLIER - i.e. per
    row in RA Directory / FL Directory / WH Directory - not per library.

    1. Reuses the existing "ApprovalStatus" site column (displayed as "Status") created
       earlier - does not recreate it if already present.
    2. Removes that field's reference from every individual RA-/FL-/WH- library (thihs only
       detaches the reference from each library - the site column definition itself, and
       anything on the directory lists, is untouched).
    3. Adds the field (by reference) to each of the 3 directory lists, positioned right
       after the "Supplier" column in the default view.
    4. Sets every existing item in each directory list that doesn't already have a Status
       to "Approved" (or whatever -DefaultValue is given).

    Safe to re-run: skips removal where there's nothing to remove, skips adding the column
    to a directory list that already has it, and only backfills items that don't already
    have a Status set.

.PARAMETER SiteUrl
    The SharePoint Online site collection URL.

.PARAMETER Prefixes
    Prefixes used to find both the individual libraries (title starts with "<prefix>-") and
    the directory lists (title "<prefix> Directory"). Defaults to RA, FL, WH.

.PARAMETER FieldInternalName
    Internal name of the existing site column to reuse. Defaults to "ApprovalStatus" (the
    one created by the earlier Add-StatusColumnToLibraries.ps1 run).

.PARAMETER Choices
    Only used if the site column doesn't already exist and has to be created from scratch.
    Defaults to Approved, Inactive.

.PARAMETER PositionAfterField
    Internal name of the column to place Status immediately after in each directory list's
    default view. Defaults to "Supplier".

.PARAMETER DefaultValue
    Value to bulk-apply to every directory list item that doesn't already have a Status.
    Defaults to "Approved".

.PARAMETER SkipRemoveFromLibraries
    If set, leaves the Status column on the individual libraries as well (doesn't remove
    it). By default this script DOES remove it from the libraries, since that placement was
    a mistake.

.PARAMETER LogPath
    Folder for the run log. Defaults to the script's own folder.

.EXAMPLE
    Connect-PnPOnline -Url "https://iammutant.sharepoint.com/sites/QA-ApprovedSupplierRawMaterial" -ClientId "YOUR-APP-CLIENT-ID" -Interactive
    .\Move-StatusColumnToDirectoryLists.ps1
#>

[CmdletBinding()]
param(
    [string]$SiteUrl = "https://iammutant.sharepoint.com/sites/QA-ApprovedSupplierRawMaterial",
    [string[]]$Prefixes = @("RA", "FL", "WH"),
    [string]$FieldInternalName = "ApprovalStatus",
    [string[]]$Choices = @("Approved", "Inactive"),
    [string]$PositionAfterField = "Supplier",
    [string]$DefaultValue = "Approved",
    [switch]$SkipRemoveFromLibraries,
    [string]$LogPath
)

# ---------------------------------------------------------------------------
# 0. SETUP
# ---------------------------------------------------------------------------

function Remove-SurroundingQuotes {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    return $Value.Trim().Trim('"').Trim("'")
}

$SiteUrl      = Remove-SurroundingQuotes $SiteUrl
$DefaultValue = Remove-SurroundingQuotes $DefaultValue
$LogPath      = Remove-SurroundingQuotes $LogPath

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $LogPath = if ($PSScriptRoot) { $PSScriptRoot } else { $env:TEMP }
}
if (-not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null }

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell module not found. Install with: Install-Module PnP.PowerShell -Scope CurrentUser"
}
try {
    Get-PnPContext -ErrorAction Stop | Out-Null
} catch {
    throw "No active PnP connection found. Run Connect-PnPOnline -Url '$SiteUrl' -ClientId '<your app id>' -Interactive first, then re-run this script."
}

$script:LogFile = Join-Path $LogPath ("Move-StatusColumnToDirectoryLists_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
$script:Stats = @{ RemovedFromLibraries = 0; ListsUpdated = 0; ListsSkipped = 0; ItemsBackfilled = 0; Failed = 0 }

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "ADDED", "REMOVED", "SKIPPED", "WARN", "FAILED")]
        [string]$Level = "INFO"
    )
    $line = "[{0:yyyy-MM-dd HH:mm:ss}] [{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content -Path $script:LogFile -Value $line
    $color = switch ($Level) { "ADDED" {"Green"} "REMOVED" {"Yellow"} "SKIPPED" {"Yellow"} "WARN" {"DarkYellow"} "FAILED" {"Red"} default {"Gray"} }
    Write-Host $line -ForegroundColor $color
}

Write-Log "=== Move-StatusColumnToDirectoryLists run started ===" INFO
Write-Log "Site: $SiteUrl / Prefixes: $($Prefixes -join ', ') / Field: '$FieldInternalName' (displayed as Status) / DefaultValue: '$DefaultValue'" INFO

# ---------------------------------------------------------------------------
# 1. RESOLVE (OR CREATE) THE SHARED SITE COLUMN
# ---------------------------------------------------------------------------

$siteField = Get-PnPField -Identity $FieldInternalName -ErrorAction SilentlyContinue
if (-not $siteField) {
    Write-Log "Site column '$FieldInternalName' not found - creating it as a Choice field." INFO
    $choicesXml = ($Choices | ForEach-Object { "<CHOICE>$_</CHOICE>" }) -join ""
    $fieldGuid = [Guid]::NewGuid().ToString()
    # GOTCHA: Add-PnPFieldFromXml needs an explicit ID (GUID) and StaticName
    # in the CAML, or it throws a bare "Object reference not set to an
    # instance of an object" - it does not reliably auto-generate an ID.
    $fieldXml = "<Field Type='Choice' DisplayName='Status' Name='$FieldInternalName' StaticName='$FieldInternalName' ID='{$fieldGuid}' Format='Dropdown' Group='Custom Columns'><CHOICES>$choicesXml</CHOICES></Field>"
    Add-PnPFieldFromXml -FieldXml $fieldXml | Out-Null
    # GOTCHA: don't trust Add-PnPFieldFromXml's return value - always
    # re-fetch explicitly, or downstream -Field $siteField calls fail with
    # "Cannot bind argument to parameter 'Field' because it is null."
    $siteField = Get-PnPField -Identity $FieldInternalName -ErrorAction Stop
    Write-Log "Created site column '$FieldInternalName' displayed as 'Status'." ADDED
} else {
    Write-Log "Site column '$FieldInternalName' already exists - reusing it." INFO
}
if (-not $siteField) {
    throw "Could not resolve site column '$FieldInternalName' - aborting before making any changes."
}

# ---------------------------------------------------------------------------
# 2. REMOVE THE FIELD FROM INDIVIDUAL LIBRARIES (undoing the earlier mistake)
# ---------------------------------------------------------------------------

function Get-PrefixLibraries {
    param([string]$Prefix)
    # BaseTemplate 101 = Document Library
    Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and $_.Title -like "$Prefix-*" }
}

if (-not $SkipRemoveFromLibraries) {
    foreach ($prefix in $Prefixes) {
        $libraries = Get-PrefixLibraries -Prefix $prefix
        Write-Log "--- Prefix '$prefix-': checking $($libraries.Count) libraries for '$FieldInternalName' to remove ---" INFO

        foreach ($lib in $libraries) {
            try {
                $existingListField = Get-PnPField -List $lib -Identity $FieldInternalName -ErrorAction SilentlyContinue
                if ($existingListField) {
                    Remove-PnPField -List $lib -Identity $FieldInternalName -Force
                    Write-Log "Removed 'Status' column from library '$($lib.Title)'." REMOVED
                    $script:Stats.RemovedFromLibraries++
                }
            }
            catch {
                Write-Log "FAILED removing Status from library '$($lib.Title)': $($_.Exception.Message)" FAILED
                $script:Stats.Failed++
            }
        }
    }
} else {
    Write-Log "SkipRemoveFromLibraries set - leaving Status on individual libraries untouched." INFO
}

# ---------------------------------------------------------------------------
# 3. ADD THE FIELD TO EACH DIRECTORY LIST, POSITIONED AFTER Supplier
# ---------------------------------------------------------------------------

foreach ($prefix in $Prefixes) {
    $listTitle = "$prefix Directory"
    try {
        $list = Get-PnPList -Identity $listTitle -ErrorAction Stop
    }
    catch {
        Write-Log "FAILED: directory list '$listTitle' not found - skipping this prefix." FAILED
        $script:Stats.Failed++
        continue
    }

    $existingListField = Get-PnPField -List $listTitle -Identity $FieldInternalName -ErrorAction SilentlyContinue
    if ($existingListField) {
        Write-Log "'$listTitle' already has the '$FieldInternalName' column - skipping add." SKIPPED
        $script:Stats.ListsSkipped++
    }
    else {
        try {
            # GOTCHA: Add-PnPField's "add existing field by reference"
            # parameter set (-List + -Field) does NOT include
            # -AddToDefaultView - combining them throws "Parameter set
            # cannot be resolved". Adding to the view is a separate step.
            Add-PnPField -List $listTitle -Field $siteField -ErrorAction Stop | Out-Null

            $view = Get-PnPView -List $listTitle | Where-Object { $_.DefaultView } | Select-Object -First 1
            if ($view) {
                $currentFields = @($view.ViewFields)
                if ($currentFields -notcontains $FieldInternalName) {
                    $anchorIndex = -1
                    for ($i = 0; $i -lt $currentFields.Count; $i++) {
                        if ($currentFields[$i] -ieq $PositionAfterField) { $anchorIndex = $i; break }
                    }
                    if ($anchorIndex -ge 0) {
                        $newFields = @()
                        $newFields += $currentFields[0..$anchorIndex]
                        $newFields += $FieldInternalName
                        if ($anchorIndex + 1 -lt $currentFields.Count) {
                            $newFields += $currentFields[($anchorIndex + 1)..($currentFields.Count - 1)]
                        }
                    } else {
                        Write-Log "Anchor column '$PositionAfterField' not found in '$listTitle''s view - appending 'Status' at the end instead." WARN
                        $newFields = $currentFields + @($FieldInternalName)
                    }
                    Set-PnPView -List $listTitle -Identity $view.Id -Fields $newFields | Out-Null
                }
            }

            Write-Log "Added 'Status' column to '$listTitle'." ADDED
            $script:Stats.ListsUpdated++
        }
        catch {
            Write-Log "FAILED adding Status to '$listTitle': $($_.Exception.Message)" FAILED
            $script:Stats.Failed++
            continue
        }
    }

    # ---------------------------------------------------------------------
    # 4. BACKFILL: set every existing supplier row without a Status yet
    # ---------------------------------------------------------------------
    try {
        $items = Get-PnPListItem -List $listTitle -PageSize 500 -Fields $FieldInternalName
        $updatedHere = 0
        foreach ($item in $items) {
            if ([string]::IsNullOrWhiteSpace("$($item[$FieldInternalName])")) {
                Set-PnPListItem -List $listTitle -Identity $item.Id -Values @{ $FieldInternalName = $DefaultValue } | Out-Null
                $updatedHere++
                $script:Stats.ItemsBackfilled++
            }
        }
        Write-Log "Backfilled Status='$DefaultValue' on $updatedHere supplier row(s) in '$listTitle' (out of $($items.Count) total)." INFO
    }
    catch {
        Write-Log "FAILED backfilling '$listTitle': $($_.Exception.Message)" FAILED
        $script:Stats.Failed++
    }
}

Write-Log "=== Run complete: RemovedFromLibraries=$($script:Stats.RemovedFromLibraries) ListsUpdated=$($script:Stats.ListsUpdated) ListsSkipped=$($script:Stats.ListsSkipped) ItemsBackfilled=$($script:Stats.ItemsBackfilled) Failed=$($script:Stats.Failed) ===" INFO
Write-Host ""
Write-Host "Summary: RemovedFromLibraries=$($script:Stats.RemovedFromLibraries)  ListsUpdated=$($script:Stats.ListsUpdated)  ListsSkipped=$($script:Stats.ListsSkipped)  ItemsBackfilled=$($script:Stats.ItemsBackfilled)  Failed=$($script:Stats.Failed)" -ForegroundColor Cyan
Write-Host "Full log: $script:LogFile" -ForegroundColor Cyan
