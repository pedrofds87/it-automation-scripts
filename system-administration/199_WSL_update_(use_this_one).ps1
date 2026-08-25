# Script: WSL update (use this one)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 199

$ErrorActionPreference = "Stop"
$fixedVersion = [version]"2.6.2"

function Normalize-Out($s) {
    if (-not $s) { return "" }
    # Ninja sometimes displays spaced characters; collapse whitespace
    return ([regex]::Replace($s, '\s+', ' ')).Trim()
}

function Parse-Version($text) {
    $m = [regex]::Match($text, '(\d+\.\d+\.\d+(\.\d+)?)')
    if ($m.Success) { return [version]$m.Groups[1].Value }
    return $null
}

function Get-WslVersionBestEffort {
    foreach ($arg in @("--version","--status")) {
        try {
            $raw = (& wsl.exe $arg 2>&1 | Out-String)
            $norm = Normalize-Out $raw
            $v = Parse-Version $norm
            if ($v) { return $v }
        } catch { }
    }
    return $null
}

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-Error "wsl.exe not found."
    exit 1
}

$installed = Get-WslVersionBestEffort
if ($installed) {
    Write-Host ("Detected WSL version: " + $installed)
    Write-Host ("Fixed version target: " + $fixedVersion)
    if ($installed -ge $fixedVersion) {
        Write-Host "WSL already compliant. Exiting."
        exit 0
    }
} else {
    Write-Host "Could not determine WSL version. Will attempt update anyway."
}

Write-Host "Running: wsl.exe --update"
$updateRaw = (& wsl.exe --update 2>&1 | Out-String)
$updateNorm = Normalize-Out $updateRaw
Write-Host $updateNorm

# If output explicitly mentions updating to the fixed version, treat as success
if ($updateNorm -match "Updating Windows Subsystem for Linux to version:\s*2\.6\.2") {
    Write-Host "Update output confirms target version 2.6.2."
    exit 0
}

# Otherwise, try verifying post-update
$after = Get-WslVersionBestEffort
if ($after) {
    Write-Host ("WSL version after update: " + $after)
    if ($after -ge $fixedVersion) {
        Write-Host "Update successful."
        exit 0
    } else {
        Write-Warning "Update ran but version still below target."
        exit 1
    }
}

Write-Host "Update completed; version could not be verified in this context."
exit 0
