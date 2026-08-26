<#
.SYNOPSIS
    Builds a searchable directory experience for the RA / FL / WH document libraries
    on https://YOUR-TENANT.sharepoint.com/sites/QA-ApprovedSupplierRawMaterial, replacing
    300+ Quick Launch entries with 3 searchable directory pages.

.DESCRIPTION
    1. Creates (or reuses) 3 Generic Lists: "RA Directory", "FL Directory", "WH Directory"
       with columns: ItemNo (Text), Description (Note), Supplier (Text), LibraryUrl (Hyperlink)
    2. Reads "RAW Inventory Details.xlsx" (Item No. / ItemDescription / SupplierName) and
       builds a lookup table keyed on Item No.
    3. Enumerates existing document libraries by title prefix (RA-, FL-, WH-), matches each
       one to the Excel data by Item No., and inserts one directory-list entry per library.
       Duplicates (by ItemNo) are skipped - the script is safe to re-run.
    4. Writes the Library URL into the Hyperlink column using the ONLY reliable syntax for
       Add-PnPListItem against a Hyperlink/URL field in PnP PowerShell 3.1 - see the
       "HYPERLINK FIELD FIX" note below. This is what was failing before with:
           Invalid URL: Microsoft.SharePoint.Client.FieldUrlValue
    5. Creates 3 modern pages (RA/FL/WH Directory Page) each containing a modern "List"
       web part bound to the corresponding directory list. The modern List web part ships
       with built-in search / filter / sort, so no extra work is needed there.
    6. Adds exactly 3 Quick Launch nodes (Raw Materials (RA), Flavours (FL), Whey Proteins (WH))
       pointing at the 3 pages.
    7. Sets OnQuickLaunch = $false on every RA-/FL-/WH- library so they disappear from the
       left nav WITHOUT touching permissions or making the library itself hidden/inaccessible.

    Re-running the script is safe: every creation step first checks whether the target
    (list, field, list item, page, nav node) already exists and skips it if so. Run summary
    counts (added / skipped / duplicate / failed) are written to the console and to a log file.

.PARAMETER SiteUrl
    The SharePoint Online site collection URL.

.PARAMETER ExcelPath
    Full path to "RAW Inventory Details.xlsx".

.PARAMETER LogPath
    Folder where the run log (Build-SharePointDirectory_yyyyMMdd_HHmmss.log) is written.
    Defaults to the folder the script itself is saved in (falls back to %TEMP% if that
    can't be determined).

.PARAMETER SkipHideFromQuickLaunch
    If set, step 7 (hiding the individual RA-/FL-/WH- libraries from Quick Launch) is skipped.
    Useful the first time you run this, so you can verify the directory pages work before
    removing the old navigation.

.NOTES
    Prerequisites (per the prompt, already satisfied in your environment):
      - PnP.PowerShell 3.1.0, already connected via Connect-PnPOnline (this script does NOT
        call Connect-PnPOnline itself - it uses whatever PnP connection is already active in
        the session, so it also works fine with -ReturnConnection / multiple connections).
      - ImportExcel module installed (Install-Module ImportExcel -Scope CurrentUser).

.EXAMPLE
    Connect-PnPOnline -Url "https://YOUR-TENANT.sharepoint.com/sites/QA-ApprovedSupplierRawMaterial" -Interactive
    .\Build-SharePointDirectory.ps1 -ExcelPath "C:\Data\RAW Inventory Details.xlsx" -SkipHideFromQuickLaunch

    # Verify the 3 directory pages look right, then run again without -SkipHideFromQuickLaunch
    # to remove the individual libraries from Quick Launch.
#>

[CmdletBinding()]
param(
    [string]$SiteUrl = "https://YOUR-TENANT.sharepoint.com/sites/QA-ApprovedSupplierRawMaterial",
    [Parameter(Mandatory = $true)]
    [string]$ExcelPath,
    [string]$LogPath,
    [switch]$SkipHideFromQuickLaunch
)

# ---------------------------------------------------------------------------
# 0. SETUP
# ---------------------------------------------------------------------------

# Defensive cleanup: if a value was typed at an interactive parameter prompt
# with surrounding quotes (e.g. "C:\Temp\file.xlsx"), those quote characters
# become part of the literal string rather than being stripped like they
# would be on the command line. Strip any leading/trailing " or ' here so
# both prompted input and normal -Param "..." usage behave the same way.
function Remove-SurroundingQuotes {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    return $Value.Trim().Trim('"').Trim("'")
}

$SiteUrl   = Remove-SurroundingQuotes $SiteUrl
$ExcelPath = Remove-SurroundingQuotes $ExcelPath
$LogPath   = Remove-SurroundingQuotes $LogPath

# Default log folder = the script's own directory (falls back to %TEMP% if
# that can't be determined, e.g. when the script body is pasted directly
# into a console). Never defaults to "." - that resolves to whatever folder
# the shell happened to be sitting in (which can be a locked-down system
# folder like C:\Windows\System32) rather than somewhere the script can
# actually write.
if ([string]::IsNullOrWhiteSpace($LogPath)) {
    if ($PSScriptRoot) {
        $LogPath = $PSScriptRoot
    } else {
        $LogPath = $env:TEMP
    }
}
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell module not found. Install with: Install-Module PnP.PowerShell -Scope CurrentUser"
}
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    throw "ImportExcel module not found. Install with: Install-Module ImportExcel -Scope CurrentUser"
}
Import-Module ImportExcel -ErrorAction Stop

try {
    $ctxCheck = Get-PnPContext -ErrorAction Stop
} catch {
    throw "No active PnP connection found. Run Connect-PnPOnline -Url '$SiteUrl' first, then re-run this script."
}

$script:LogFile = Join-Path $LogPath ("Build-SharePointDirectory_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
$script:Stats = @{ Added = 0; Skipped = 0; Duplicate = 0; Failed = 0 }

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "ADDED", "SKIPPED", "DUPLICATE", "FAILED", "WARN")]
        [string]$Level = "INFO"
    )
    $line = "[{0:yyyy-MM-dd HH:mm:ss}] [{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content -Path $script:LogFile -Value $line
    switch ($Level) {
        "ADDED"     { $script:Stats.Added++;     Write-Host $line -ForegroundColor Green }
        "SKIPPED"   { $script:Stats.Skipped++;   Write-Host $line -ForegroundColor Yellow }
        "DUPLICATE" { $script:Stats.Duplicate++; Write-Host $line -ForegroundColor Yellow }
        "FAILED"    { $script:Stats.Failed++;    Write-Host $line -ForegroundColor Red }
        "WARN"      { Write-Host $line -ForegroundColor DarkYellow }
        default     { Write-Host $line }
    }
}

Write-Log "=== Build-SharePointDirectory run started ===" INFO
Write-Log "Site: $SiteUrl" INFO
Write-Log "Excel source: $ExcelPath" INFO

# Prefix -> friendly config used throughout the script
$PrefixConfig = @(
    @{ Prefix = "RA"; ListTitle = "RA Directory"; PageName = "RADirectory";  PageTitle = "RA Directory Page"; NavTitle = "Raw Materials (RA)"  }
    @{ Prefix = "FL"; ListTitle = "FL Directory"; PageName = "FLDirectory";  PageTitle = "FL Directory Page"; NavTitle = "Flavours (FL)"        }
    @{ Prefix = "WH"; ListTitle = "WH Directory"; PageName = "WHDirectory";  PageTitle = "WH Directory Page"; NavTitle = "Whey Proteins (WH)"   }
)

# ---------------------------------------------------------------------------
# 1. IMPORT EXCEL SOURCE DATA -> hashtable keyed by Item No.
# ---------------------------------------------------------------------------

function Import-SourceData {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Excel file not found: $Path"
    }

    $rows = Import-Excel -Path $Path
    $lookup = @{}

    foreach ($row in $rows) {
        $itemNo = "$($row.'Item No.')".Trim()
        if ([string]::IsNullOrWhiteSpace($itemNo)) { continue }

        # last write wins if the sheet somehow has a duplicate Item No.
        $lookup[$itemNo] = [PSCustomObject]@{
            ItemNo      = $itemNo
            Description = "$($row.ItemDescription)".Trim()
            Supplier    = "$($row.SupplierName)".Trim()
        }
    }

    Write-Log "Loaded $($lookup.Count) rows from Excel source." INFO
    return $lookup
}

# ---------------------------------------------------------------------------
# 2. ENSURE DIRECTORY LIST + COLUMNS EXIST (idempotent)
# ---------------------------------------------------------------------------

function Ensure-DirectoryList {
    param([string]$ListTitle)

    $list = Get-PnPList -Identity $ListTitle -ErrorAction SilentlyContinue
    if (-not $list) {
        Write-Log "Creating list '$ListTitle'." INFO
        $list = New-PnPList -Title $ListTitle -Template GenericList -OnQuickLaunch:$false
    } else {
        Write-Log "List '$ListTitle' already exists - reusing." INFO
    }

    $fieldsToEnsure = @(
        @{ Internal = "ItemNo";      Display = "Item No.";    Type = "Text" }
        @{ Internal = "Description"; Display = "Description"; Type = "Note" }
        @{ Internal = "Supplier";    Display = "Supplier";    Type = "Text" }
        @{ Internal = "LibraryUrl";  Display = "Library URL"; Type = "URL"  }
    )

    foreach ($f in $fieldsToEnsure) {
        $existing = Get-PnPField -List $ListTitle -Identity $f.Internal -ErrorAction SilentlyContinue
        if (-not $existing) {
            Write-Log "Adding column '$($f.Display)' ($($f.Internal)) to '$ListTitle'." INFO
            Add-PnPField -List $ListTitle -DisplayName $f.Display -InternalName $f.Internal `
                -Type $f.Type -AddToDefaultView | Out-Null
        }
    }

    # Always force the default view to show the columns we care about.
    # -AddToDefaultView above only takes effect the moment a field is first
    # created - if the list (or a field on it) pre-existed before this script
    # ever ran against it, that flag never fires and the view is left showing
    # only "Title". Re-applying the view field list on every run fixes that
    # regardless of the list's history, and is a harmless no-op once correct.
    $desiredViewFields = @("LinkTitle", "ItemNo", "Description", "Supplier", "LibraryUrl")
    $defaultView = Get-PnPView -List $ListTitle | Where-Object { $_.DefaultView } | Select-Object -First 1
    if ($defaultView) {
        try {
            Set-PnPView -List $ListTitle -Identity $defaultView.Id -Fields $desiredViewFields -ErrorAction Stop
        }
        catch {
            # Some list templates use plain "Title" instead of the linked "LinkTitle" column
            try {
                Set-PnPView -List $ListTitle -Identity $defaultView.Id `
                    -Fields @("Title", "ItemNo", "Description", "Supplier", "LibraryUrl") -ErrorAction Stop
            }
            catch {
                Write-Log "WARN: could not update default view fields for '$ListTitle': $($_.Exception.Message)" WARN
            }
        }
    }

    return Get-PnPList -Identity $ListTitle
}

# ---------------------------------------------------------------------------
# 3. HYPERLINK FIELD FIX
#
# PnP PowerShell 3.1's Add-PnPListItem / Set-PnPListItem accept a Hyperlink /
# URL field value as a single STRING in the form "URL, Description" inside
# the -Values hashtable. Passing a Microsoft.SharePoint.Client.FieldUrlValue
# object (or a nested hashtable) is what throws:
#     Invalid URL: Microsoft.SharePoint.Client.FieldUrlValue
#
# Correct pattern:
#     $values = @{ LibraryUrl = "https://.../Library, Open Library" }
#     Add-PnPListItem -List $listTitle -Values $values
#
# If you need to UPDATE an existing item's hyperlink field instead of
# creating it, the same comma-string syntax works with Set-PnPListItem too:
#     Set-PnPListItem -List $listTitle -Identity $itemId -Values $values
# ---------------------------------------------------------------------------

function New-HyperlinkFieldValue {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [string]$Description = "Open Library"
    )
    return "$Url, $Description"
}

# ---------------------------------------------------------------------------
# 4. LIBRARY DISCOVERY / TITLE PARSING
# ---------------------------------------------------------------------------

function Get-PrefixLibraries {
    param([string]$Prefix)

    # BaseTemplate 101 = Document Library
    Get-PnPList | Where-Object {
        $_.BaseTemplate -eq 101 -and $_.Title -like "$Prefix-*"
    }
}

function Parse-LibraryTitle {
    <#
        Fallback parser used only when an Item No. from a library title has no
        matching row in the Excel source. Handles titles like:
            "RA-0002 Beta Alanine (AHA)"
            "FL-0001 Nat Baked Cookie Flavour Type SD #34244 (VIRGINIA DARE EXTRACT CO)"
    #>
    param([string]$Title)

    $itemNo = ($Title -split '\s+', 2)[0].Trim()
    $rest   = ($Title -split '\s+', 2)[1]

    $supplier = ""
    $description = $rest
    if ($rest -match '^(?<desc>.+?)\s*\((?<supp>[^)]+)\)\s*$') {
        $description = $Matches.desc.Trim()
        $supplier    = $Matches.supp.Trim()
    }

    return [PSCustomObject]@{
        ItemNo      = $itemNo
        Description = $description
        Supplier    = $supplier
    }
}

# ---------------------------------------------------------------------------
# 5. POPULATE A DIRECTORY LIST FROM ITS LIBRARIES
# ---------------------------------------------------------------------------

function Populate-DirectoryList {
    param(
        [string]$Prefix,
        [string]$ListTitle,
        [hashtable]$ExcelData
    )

    # Existing ItemNo values already in the directory list -> duplicate guard
    $existingItems = Get-PnPListItem -List $ListTitle -PageSize 500
    $existingItemNos = New-Object System.Collections.Generic.HashSet[string]
    foreach ($it in $existingItems) {
        $v = $it["ItemNo"]
        if ($v) { [void]$existingItemNos.Add("$v") }
    }

    $libraries = Get-PrefixLibraries -Prefix $Prefix
    Write-Log "Found $($libraries.Count) libraries with prefix '$Prefix-'." INFO

    foreach ($lib in $libraries) {
        try {
            $parsed = Parse-LibraryTitle -Title $lib.Title
            $itemNo = $parsed.ItemNo

            if ($existingItemNos.Contains($itemNo)) {
                Write-Log "ItemNo '$itemNo' already present in '$ListTitle' - skipping." DUPLICATE
                continue
            }

            # Prefer Excel data for Description / Supplier; fall back to the parsed title
            if ($ExcelData.ContainsKey($itemNo)) {
                $description = $ExcelData[$itemNo].Description
                $supplier    = $ExcelData[$itemNo].Supplier
            } else {
                Write-Log "ItemNo '$itemNo' not found in Excel source - using title parsing fallback." WARN
                $description = $parsed.Description
                $supplier    = $parsed.Supplier
            }

            $libraryUrl = $lib.RootFolder.ServerRelativeUrl
            $webUrl = (Get-PnPWeb).Url.TrimEnd('/')
            $fullUrl = if ($libraryUrl -match '^https?://') { $libraryUrl } else {
                # ServerRelativeUrl already includes the site path; build an absolute URL
                $siteBase = ([Uri]$SiteUrl).GetLeftPart([System.UriPartial]::Authority)
                "$siteBase$libraryUrl"
            }

            $values = @{
                Title       = $itemNo
                ItemNo      = $itemNo
                Description = $description
                Supplier    = $supplier
                LibraryUrl  = New-HyperlinkFieldValue -Url $fullUrl -Description "Open Library"
            }

            Add-PnPListItem -List $ListTitle -Values $values | Out-Null
            [void]$existingItemNos.Add($itemNo)
            Write-Log "Added '$itemNo' ($($lib.Title)) to '$ListTitle'." ADDED
        }
        catch {
            Write-Log "FAILED on library '$($lib.Title)': $($_.Exception.Message)" FAILED
        }
    }
}

# ---------------------------------------------------------------------------
# 5b. REPAIR PASS: fix Title on items that were already inserted before the
#     Title field was set on creation. Safe to re-run - only touches items
#     whose Title is currently blank, and does nothing once they're fixed.
# ---------------------------------------------------------------------------

function Repair-BlankTitles {
    param([string]$ListTitle)

    $items = Get-PnPListItem -List $ListTitle -PageSize 500
    foreach ($it in $items) {
        $currentTitle = $it["Title"]
        $itemNo = $it["ItemNo"]

        if ([string]::IsNullOrWhiteSpace($currentTitle) -and -not [string]::IsNullOrWhiteSpace($itemNo)) {
            try {
                Set-PnPListItem -List $ListTitle -Identity $it.Id -Values @{ Title = $itemNo } | Out-Null
                Write-Log "Repaired blank Title on item $($it.Id) ('$itemNo') in '$ListTitle'." ADDED
            }
            catch {
                Write-Log "FAILED to repair Title for item $($it.Id) in '$ListTitle': $($_.Exception.Message)" FAILED
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 6. MODERN DIRECTORY PAGE (search / filter / sort come from the modern List
#    web part itself - no extra web parts required)
# ---------------------------------------------------------------------------

function Ensure-DirectoryPage {
    param(
        [string]$PageName,
        [string]$PageTitle,
        [string]$ListTitle
    )

    $pageFileName = "$PageName.aspx"
    $existingPage = Get-PnPPage -Identity $pageFileName -ErrorAction SilentlyContinue

    if ($existingPage) {
        Write-Log "Page '$pageFileName' already exists - reusing." INFO
        return $existingPage
    }

    Write-Log "Creating page '$pageFileName'." INFO
    $page = Add-PnPPage -Name $PageName -Title $PageTitle -LayoutType Article -CommentsEnabled:$false
    Add-PnPPageSection -Page $page -SectionTemplate OneColumn -Order 1

    $list = Get-PnPList -Identity $ListTitle
    Add-PnPPageWebPart -Page $page -DefaultWebPartType List -Section 1 -Column 1 `
        -WebPartProperties @{ selectedListId = $list.Id.Guid.ToString() } | Out-Null

    $page.Publish()
    Write-Log "Page '$pageFileName' created and published, bound to '$ListTitle'." ADDED
    return $page
}

# ---------------------------------------------------------------------------
# 7. QUICK LAUNCH: add the 3 directory nav nodes (idempotent)
# ---------------------------------------------------------------------------

function Ensure-QuickLaunchNode {
    param(
        [string]$Title,
        [string]$PageUrlRelative   # e.g. "SitePages/RADirectory.aspx"
    )

    $existing = Get-PnPNavigationNode -Location QuickLaunch | Where-Object { $_.Title -eq $Title }
    if ($existing) {
        Write-Log "Quick Launch node '$Title' already exists - skipping." SKIPPED
        return
    }

    Add-PnPNavigationNode -Location QuickLaunch -Title $Title -Url $PageUrlRelative | Out-Null
    Write-Log "Added Quick Launch node '$Title' -> $PageUrlRelative." ADDED
}

# ---------------------------------------------------------------------------
# 8. HIDE INDIVIDUAL LIBRARIES FROM QUICK LAUNCH (does NOT hide the library
#    itself or change permissions - it stays directly accessible by URL)
# ---------------------------------------------------------------------------

function Hide-LibraryFromQuickLaunch {
    param([Microsoft.SharePoint.Client.List]$List)

    if ($List.OnQuickLaunch -eq $false) {
        Write-Log "'$($List.Title)' already off Quick Launch - skipping." SKIPPED
        return
    }

    try {
        $List.OnQuickLaunch = $false
        $List.Update()
        Invoke-PnPQuery
        Write-Log "Removed '$($List.Title)' from Quick Launch (library still accessible directly)." ADDED
    }
    catch {
        Write-Log "FAILED to update Quick Launch flag for '$($List.Title)': $($_.Exception.Message)" FAILED
    }
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

$excelData = Import-SourceData -Path $ExcelPath

foreach ($cfg in $PrefixConfig) {
    Write-Log "--- Processing prefix '$($cfg.Prefix)' ---" INFO

    # Step 1-4: list + columns + populate
    Ensure-DirectoryList -ListTitle $cfg.ListTitle | Out-Null
    Populate-DirectoryList -Prefix $cfg.Prefix -ListTitle $cfg.ListTitle -ExcelData $excelData
    Repair-BlankTitles -ListTitle $cfg.ListTitle

    # Step 5-6: modern page + quick launch node
    $page = Ensure-DirectoryPage -PageName $cfg.PageName -PageTitle $cfg.PageTitle -ListTitle $cfg.ListTitle
    $pageRelativeUrl = "SitePages/$($cfg.PageName).aspx"
    Ensure-QuickLaunchNode -Title $cfg.NavTitle -PageUrlRelative $pageRelativeUrl

    # Step 7: hide the individual libraries from Quick Launch (optional / can be deferred)
    if (-not $SkipHideFromQuickLaunch) {
        $libs = Get-PrefixLibraries -Prefix $cfg.Prefix
        foreach ($lib in $libs) {
            Hide-LibraryFromQuickLaunch -List $lib
        }
    } else {
        Write-Log "SkipHideFromQuickLaunch set - leaving '$($cfg.Prefix)-' libraries in Quick Launch for now." WARN
    }
}

Write-Log "=== Run complete: Added=$($script:Stats.Added) Skipped=$($script:Stats.Skipped) Duplicate=$($script:Stats.Duplicate) Failed=$($script:Stats.Failed) ===" INFO
Write-Host ""
Write-Host "Summary: Added=$($script:Stats.Added)  Skipped=$($script:Stats.Skipped)  Duplicate=$($script:Stats.Duplicate)  Failed=$($script:Stats.Failed)" -ForegroundColor Cyan
Write-Host "Full log: $script:LogFile" -ForegroundColor Cyanh
