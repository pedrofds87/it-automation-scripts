<#
.SYNOPSIS
    Creates/verifies a "Visitors" SharePoint group with Read-only permission, mirrors its
    membership from the site's built-in Visitors permission group, adds a People web part
    snapshot of that membership to the Home page, and publishes the page.

.DESCRIPTION
    1. Creates the "Visitors" SharePoint group if it doesn't exist (reuses it if it does).
    2. Ensures that group has exactly Read permission on the site - adds Read if missing,
       removes anything higher than Read if present. Never touches Owners or Members groups.
    3. Reads the site's actual built-in/associated Visitors permission group (whatever it's
       really named - e.g. "<Site Name> Visitors") and mirrors its membership into the
       "Visitors" group: adds anyone missing, removes anyone who's no longer a source member.
    4. Adds (or updates, if already present) a People web part titled "Visitors" to the Home
       page, populated with the current Visitors group membership - name, photo (resolved
       automatically from each person's profile), and job title where Azure AD / the user
       profile service exposes one.
    5. Publishes the Home page.
    6. Prints a summary: group created/verified, permission level, members synced, page
       update status, and where the web part was placed.

    IMPORTANT - read before relying on requirement #11 ("web part updates automatically"):
    SharePoint's out-of-the-box modern People web part cannot bind live to a SharePoint
    group membership - it only stores a fixed list of people set at the time the page was
    last saved. There is no native "dynamic" mode. This script's People web part is
    therefore a SNAPSHOT: it reflects Visitors group membership as of the moment you run
    this script. Re-running the script (safe / idempotent) re-syncs membership and
    refreshes the web part to match. If you need true real-time updates with no re-run
    required, that needs a custom SPFx web part (or a third-party one) - not something
    achievable with stock SharePoint Online + PnP PowerShell.

.PARAMETER SiteUrl
    The SharePoint Online site collection URL.

.PARAMETER GroupName
    Name of the SharePoint permission group to create/verify. Defaults to "Visitors" (see
    the naming-mismatch note above - change this if you actually want "R&D Visitors").

.PARAMETER LogPath
    Folder where the run log is written. Defaults to the script's own folder.

.PARAMETER SkipRemoveExtraMembers
    If set, membership sync only ADDS missing members - it will not remove anyone from the
    "Visitors" group who isn't in the source Visitors group. Useful for a first, cautious run.

.EXAMPLE
    Connect-PnPOnline -Url "https://YOUR-TENANT.sharepoint.com/sites/QA-ApprovedSupplierRawMaterial" -Interactive
    .\Setup-VisitorsGroupAndWebPart.ps1
#>

[CmdletBinding()]
param(
    [string]$SiteUrl = "https://YOUR-TENANT.sharepoint.com/sites/QA-ApprovedSupplierRawMaterial",
    [string]$GroupName = "Visitors",
    [string]$LogPath,
    [switch]$SkipRemoveExtraMembers
)

# ---------------------------------------------------------------------------
# 0. SETUP
# ---------------------------------------------------------------------------

function Remove-SurroundingQuotes {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    return $Value.Trim().Trim('"').Trim("'")
}

$SiteUrl   = Remove-SurroundingQuotes $SiteUrl
$GroupName = Remove-SurroundingQuotes $GroupName
$LogPath   = Remove-SurroundingQuotes $LogPath

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $LogPath = if ($PSScriptRoot) { $PSScriptRoot } else { $env:TEMP }
}
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell module not found. Install with: Install-Module PnP.PowerShell -Scope CurrentUser"
}
try {
    Get-PnPContext -ErrorAction Stop | Out-Null
} catch {
    throw "No active PnP connection found. Run Connect-PnPOnline -Url '$SiteUrl' first, then re-run this script."
}

$script:LogFile = Join-Path $LogPath ("Setup-VisitorsGroupAndWebPart_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
$script:Stats = @{
    MembersAdded    = 0
    MembersRemoved  = 0
    MembersUnchanged = 0
    JobTitleLookupFailures = 0
}
$script:GroupWasCreated = $false
$script:PagePublished   = $false
$script:WebPartAction   = "none"
$script:WebPartLocation = "unknown"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "ADDED", "REMOVED", "SKIPPED", "WARN", "FAILED")]
        [string]$Level = "INFO"
    )
    $line = "[{0:yyyy-MM-dd HH:mm:ss}] [{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content -Path $script:LogFile -Value $line
    $color = switch ($Level) {
        "ADDED"   { "Green" }
        "REMOVED" { "Yellow" }
        "SKIPPED" { "Yellow" }
        "WARN"    { "DarkYellow" }
        "FAILED"  { "Red" }
        default   { "Gray" }
    }
    Write-Host $line -ForegroundColor $color
}

Write-Log "=== Setup-VisitorsGroupAndWebPart run started ===" INFO
Write-Log "Site: $SiteUrl / Target group: '$GroupName'" INFO

# ---------------------------------------------------------------------------
# 1-2. CREATE/VERIFY THE VISITORS GROUP, ENFORCE EXACTLY "READ" PERMISSION
# ---------------------------------------------------------------------------

function Ensure-VisitorsGroup {
    param([string]$GroupName)

    $group = Get-PnPGroup -Identity $GroupName -ErrorAction SilentlyContinue
    if (-not $group) {
        Write-Log "Group '$GroupName' not found - creating it." INFO
        $group = New-PnPGroup -Title $GroupName
        $script:GroupWasCreated = $true
        Write-Log "Created group '$GroupName'." ADDED
    } else {
        Write-Log "Group '$GroupName' already exists - reusing." INFO
    }

    # Enforce exactly Read - no more, no less. Never touches any other group.
    $currentRoles = Get-PnPGroupPermissions -Identity $GroupName
    $currentRoleNames = $currentRoles | ForEach-Object { $_.Name }

    foreach ($roleName in $currentRoleNames) {
        if ($roleName -ne "Read") {
            Write-Log "Removing excess permission '$roleName' from '$GroupName' (Read-only requirement)." WARN
            Set-PnPGroupPermissions -Identity $GroupName -RemoveRole $roleName
        }
    }

    if ($currentRoleNames -notcontains "Read") {
        Set-PnPGroupPermissions -Identity $GroupName -AddRole "Read"
        Write-Log "Granted 'Read' permission to '$GroupName'." ADDED
    } else {
        Write-Log "'$GroupName' already has 'Read' permission." INFO
    }

    return Get-PnPGroup -Identity $GroupName
}

$visitorsGroup = Ensure-VisitorsGroup -GroupName $GroupName

# ---------------------------------------------------------------------------
# 3. FIND THE SITE'S BUILT-IN VISITORS PERMISSION GROUP (SOURCE OF TRUTH)
#    Resolved dynamically via AssociatedVisitorGroup rather than a hardcoded
#    name, since the site's real visitor group name varies per site
#    (e.g. "<Site Name> Visitors") and doesn't necessarily match $GroupName.
# ---------------------------------------------------------------------------

$web = Get-PnPWeb -Includes AssociatedVisitorGroup
$sourceGroup = $web.AssociatedVisitorGroup

if (-not $sourceGroup -or $sourceGroup.Id -eq 0) {
    Write-Log "No associated Visitors permission group found on this site via the standard association. Falling back to searching for a group with 'Visitors' in its name." WARN
    $sourceGroup = Get-PnPGroup | Where-Object { $_.Title -like "*Visitors*" -and $_.Title -ne $GroupName } | Select-Object -First 1
}

if (-not $sourceGroup) {
    Write-Log "FAILED: could not locate any source Visitors permission group to sync from. Membership sync skipped - '$GroupName' left as-is." FAILED
    $sourceMembers = @()
} else {
    Write-Log "Source Visitors permission group resolved as '$($sourceGroup.Title)'." INFO
    try {
        $sourceMembers = Get-PnPGroupMember -Group $sourceGroup -ErrorAction Stop
    }
    catch {
        Write-Log "FAILED to read members of '$($sourceGroup.Title)': $($_.Exception.Message)" FAILED
        throw
    }
    Write-Log "Source group '$($sourceGroup.Title)' has $($sourceMembers.Count) member(s)." INFO
}

# ---------------------------------------------------------------------------
# 4. SYNCHRONIZE MEMBERSHIP (mirror source -> target)
# ---------------------------------------------------------------------------

function Sync-GroupMembership {
    param(
        [string]$TargetGroupName,
        [array]$SourceMembers,
        [switch]$SkipRemove
    )

    $targetMembers = Get-PnPGroupMember -Group $TargetGroupName -ErrorAction Stop
    $sourceLoginNames = $SourceMembers | ForEach-Object { $_.LoginName }
    $targetLoginNames = $targetMembers | ForEach-Object { $_.LoginName }

    # Add anyone in source but not yet in target
    foreach ($member in $SourceMembers) {
        if ($targetLoginNames -notcontains $member.LoginName) {
            try {
                Add-PnPGroupMember -LoginName $member.LoginName -Identity $TargetGroupName | Out-Null
                Write-Log "Added '$($member.Title)' ($($member.LoginName)) to '$TargetGroupName'." ADDED
                $script:Stats.MembersAdded++
            }
            catch {
                Write-Log "FAILED to add '$($member.LoginName)' to '$TargetGroupName': $($_.Exception.Message)" FAILED
            }
        } else {
            $script:Stats.MembersUnchanged++
        }
    }

    # Remove anyone in target who is no longer in source (full mirror), unless suppressed
    if (-not $SkipRemove) {
        foreach ($member in $targetMembers) {
            if ($sourceLoginNames -notcontains $member.LoginName) {
                try {
                    Remove-PnPGroupMember -LoginName $member.LoginName -Identity $TargetGroupName | Out-Null
                    Write-Log "Removed '$($member.Title)' ($($member.LoginName)) from '$TargetGroupName' - no longer in source Visitors group." REMOVED
                    $script:Stats.MembersRemoved++
                }
                catch {
                    Write-Log "FAILED to remove '$($member.LoginName)' from '$TargetGroupName': $($_.Exception.Message)" FAILED
                }
            }
        }
    } else {
        Write-Log "SkipRemoveExtraMembers set - not removing any existing '$TargetGroupName' members." INFO
    }
}

if ($sourceMembers) {
    Sync-GroupMembership -TargetGroupName $GroupName -SourceMembers $sourceMembers -SkipRemove:$SkipRemoveExtraMembers
}

$finalMembers = Get-PnPGroupMember -Group $GroupName -ErrorAction Stop
Write-Log "'$GroupName' now has $($finalMembers.Count) member(s) after sync." INFO

# ---------------------------------------------------------------------------
# BUILD THE PERSON LIST FOR THE WEB PART (name / photo resolve automatically
# from id+upn at render time; job title is looked up best-effort below)
# ---------------------------------------------------------------------------

function Get-UpnFromLoginName {
    param([string]$LoginName)
    # Claims-encoded login names look like: i:0#.f|membership|user@domain.com
    $parts = $LoginName -split '\|'
    return $parts[-1]
}

function Get-JobTitleBestEffort {
    param([string]$Upn)

    # Try Azure AD first (requires the PnP app registration to have directory read
    # permission - silently falls back if not available in this tenant/session).
    try {
        $aadUser = Get-PnPAzureADUser -Identity $Upn -ErrorAction Stop
        if ($aadUser -and $aadUser.JobTitle) { return $aadUser.JobTitle }
    } catch { }

    # Fall back to the User Profile Service.
    try {
        $profileProps = Get-PnPUserProfileProperty -Account $Upn -ErrorAction Stop
        if ($profileProps -and $profileProps.UserProfileProperties -and $profileProps.UserProfileProperties["SPS-JobTitle"]) {
            return $profileProps.UserProfileProperties["SPS-JobTitle"]
        }
    } catch { }

    $script:Stats.JobTitleLookupFailures++
    return ""
}

$persons = @()
foreach ($member in $finalMembers) {
    $upn = Get-UpnFromLoginName -LoginName $member.LoginName
    $jobTitle = Get-JobTitleBestEffort -Upn $upn

    $persons += [PSCustomObject]@{
        id         = $upn
        upn        = $upn
        role       = $jobTitle
        department = ""
        phone      = ""
        sip        = ""
    }
}

if ($script:Stats.JobTitleLookupFailures -gt 0) {
    Write-Log "Job title lookup failed or returned nothing for $($script:Stats.JobTitleLookupFailures) of $($finalMembers.Count) member(s) - those tiles will show name/photo only." WARN
}

# ---------------------------------------------------------------------------
# 5-6. FIND / EDIT HOME PAGE, PLACE THE PEOPLE WEB PART, PUBLISH
# ---------------------------------------------------------------------------

$homePageUrl = Get-PnPHomePage
$homePageName = Split-Path $homePageUrl -Leaf
Write-Log "Home page resolved as '$homePageName'." INFO

$page = Get-PnPPage -Identity $homePageName

# Look for an existing People web part titled "Visitors" so re-runs update it
# in place instead of adding a duplicate. $page.Controls entries expose
# Type (always the literal string "PageWebPart" for any client-side web part -
# there is no separate "WebPartId" property to compare against), Title, and
# PropertiesJson. We identify "our" web part by Title plus the presence of a
# "persons" key in its PropertiesJson, which only the People web part has.
$existingWebPart = $page.Controls | Where-Object {
    $_.Type -eq "PageWebPart" -and $_.Title -eq "Visitors" -and $_.PropertiesJson -match '"persons"'
} | Select-Object -First 1

# Build the full properties payload as a JSON STRING up front. This matters:
# passing a Hashtable whose values include an array of [PSCustomObject]
# (our $persons list) straight into -WebPartProperties triggers "A possible
# object cycle was detected" - PnP's internal serializer trips over
# PSCustomObject's PSObject/Members reflection metadata. Pre-serializing with
# ConvertTo-Json (which DOES handle PSCustomObject correctly) and only ever
# handing PnP a plain string sidesteps that entirely. This is also exactly
# how Set-PnPPageWebPart -PropertiesJson is meant to be used.
$webPartPropertiesJson = @{
    title   = "Visitors"
    layout  = 1
    persons = $persons
} | ConvertTo-Json -Depth 5 -Compress

if ($existingWebPart) {
    Write-Log "Existing 'Visitors' People web part found on '$homePageName' - refreshing its membership snapshot." INFO
    try {
        Set-PnPPageWebPart -Page $homePageName -Identity $existingWebPart.InstanceId -PropertiesJson $webPartPropertiesJson
        # Set-PnPPageWebPart persists directly to the server using the page
        # name/identity - it doesn't touch our local $page object. Re-fetch
        # so $page reflects that change before we publish below (publishing
        # a stale local copy could otherwise overwrite what we just set).
        $page = Get-PnPPage -Identity $homePageName
        $script:WebPartAction = "updated"
        $script:WebPartLocation = "existing placement (unchanged)"
    }
    catch {
        Write-Log "FAILED to update existing People web part: $($_.Exception.Message)" FAILED
    }
}
else {
    Write-Log "No existing 'Visitors' People web part found - adding a new one." INFO

    # Best-effort placement: look for a control/section whose text or title
    # mentions "Site Contacts"; place the new web part in the right-hand
    # column if that section is two-column, otherwise directly below it in
    # the same column. If no such section is found, fall back to the last
    # section on the page (again preferring the right column if one exists).
    # NOTE: this is heuristic - please visually confirm placement on the page
    # after this script runs, since page layouts vary in ways a script can't
    # always parse perfectly.
    $targetSectionOrder = $null
    $targetColumn = 1
    $targetOrder = 1

    foreach ($section in $page.Sections) {
        foreach ($column in $section.Columns) {
            foreach ($control in $column.Controls) {
                $controlText = "$($control.Title)$($control.Text)"
                if ($controlText -match "Site Contacts") {
                    $targetSectionOrder = $section.Order
                    if ($section.Columns.Count -ge 2) {
                        $targetColumn = 2
                        $targetOrder = 1
                        $script:WebPartLocation = "Section $($section.Order), right-hand column (next to Site Contacts)"
                    } else {
                        $targetColumn = $column.Order
                        $targetOrder = ($column.Controls | Measure-Object -Property Order -Maximum).Maximum + 1
                        $script:WebPartLocation = "Section $($section.Order), below Site Contacts"
                    }
                }
            }
        }
    }

    if (-not $targetSectionOrder) {
        Write-Log "No 'Site Contacts' section detected - placing web part in the last section of the page instead." WARN
        $lastSection = $page.Sections | Sort-Object Order | Select-Object -Last 1
        if ($lastSection) {
            $targetSectionOrder = $lastSection.Order
            if ($lastSection.Columns.Count -ge 2) {
                $targetColumn = 2
                $script:WebPartLocation = "Last section ($($lastSection.Order)), right-hand column"
            } else {
                $targetColumn = 1
                $script:WebPartLocation = "Last section ($($lastSection.Order)), single column (appended at bottom)"
            }
        } else {
            Write-Log "Page has no sections at all - adding a new one-column section." WARN
            Add-PnPPageSection -Page $page -SectionTemplate OneColumn -Order 1
            $targetSectionOrder = 1
            $targetColumn = 1
            $script:WebPartLocation = "New section added at the top of the page"
        }
    }

    try {
        # Add the People web part with its full properties (title + persons)
        # in one shot - the same proven pattern used successfully in the
        # directory-page script (Add-PnPPageWebPart ... ; $page.Publish()),
        # rather than adding it bare and trying to locate + update it
        # afterward. That "add, then re-fetch, then find" approach kept
        # failing because Add-PnPPageWebPart only mutates the in-memory
        # $page object - a re-fetch before the page is saved silently
        # discards the not-yet-persisted control every time. Passing the
        # already-serialized JSON STRING (not a hashtable containing
        # PSCustomObjects) avoids the earlier "object cycle" error too.
        Add-PnPPageWebPart -Page $page -DefaultWebPartType People -Section $targetSectionOrder -Column $targetColumn `
            -WebPartProperties $webPartPropertiesJson | Out-Null

        $script:WebPartAction = "added"
        Write-Log "Added 'Visitors' People web part - $($script:WebPartLocation)." ADDED
    }
    catch {
        Write-Log "FAILED to add People web part: $($_.Exception.Message)" FAILED
    }
}

try {
    $page.Publish()
    $script:PagePublished = $true
    Write-Log "Home page '$homePageName' published." ADDED
}
catch {
    Write-Log "FAILED to publish '$homePageName': $($_.Exception.Message)" FAILED
}

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------

Write-Log "=== Run complete ===" INFO
Write-Host ""
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " Group '$GroupName':        $(if ($script:GroupWasCreated) {'created'} else {'verified (already existed)'})"
Write-Host " Permission level:          Read (enforced - nothing higher)"
Write-Host " Source visitor group:      $(if ($sourceGroup) { $sourceGroup.Title } else { 'NOT FOUND - sync skipped' })"
Write-Host " Members added:             $($script:Stats.MembersAdded)"
Write-Host " Members removed:           $($script:Stats.MembersRemoved)"
Write-Host " Members unchanged:         $($script:Stats.MembersUnchanged)"
Write-Host " Total members now:        $($finalMembers.Count)"
Write-Host " Home page update status:   $(if ($script:PagePublished) {'published'} else {'FAILED - see log'})"
Write-Host " People web part:           $script:WebPartAction"
Write-Host " Web part placement:        $script:WebPartLocation"
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " NOTE: the People web part is a SNAPSHOT, not a live binding." -ForegroundColor Yellow
Write-Host " Re-run this script whenever Visitors group membership changes" -ForegroundColor Yellow
Write-Host " to refresh it - SharePoint's stock People web part has no" -ForegroundColor Yellow
Write-Host " native way to reflect group membership changes automatically." -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Full log: $script:LogFile" -ForegroundColor Cyan
