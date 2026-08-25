# Script: Update Microsoft Windows Subsystem for Linux (WSL2) 
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 179

# Update-WSL.ps1
# Robust WSL updater to ensure WSL >= 2.5.10
# Run in PowerShell as Administrator

$ErrorActionPreference = 'Stop'

function Ensure-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Please run this script in an elevated PowerShell (Run as Administrator)."
        exit 1
    }
}

function Enable-WSL-Features {
    Write-Output "Ensuring Windows features for WSL are enabled..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
}

function Get-WSL-Version {
    try {
        $raw = wsl.exe --version 2>&1 | Out-String
    } catch {
        return $null
    }
    # Normalize spacing (handles weird console spacing) and remove zero-width chars
    $norm = ($raw -replace "\u200B|\u200C|\u200D|\u2060","") -replace "\s+", " "
    # Look for the first x.y.z.w pattern anywhere
    $m = [regex]::Match($norm, '\b\d+\.\d+\.\d+\.\d+\b')
    if ($m.Success) { return $m.Value }
    # Fallback: try the explicit label if present (localized consoles might differ)
    $m2 = [regex]::Match($norm, 'WSL\s*version\s*:\s*([0-9\.]+)', 'IgnoreCase')
    if ($m2.Success) { return $m2.Groups[1].Value }
    return $null
}

function Compare-Version($a, $b) {
    try {
        return ([version]$a) -ge ([version]$b)
    } catch {
        # If parsing fails, be conservative
        return $false
    }
}

Ensure-Admin

Write-Output "Checking if WSL is present..."
try {
    wsl.exe --help *>$null
} catch {
    Write-Output "WSL not detected; enabling required features..."
    Enable-WSL-Features
}

# Make sure features are on (idempotent)
Enable-WSL-Features

# Try updating via Store; if Store is unavailable, use web-download
Write-Output "Attempting WSL update (Store first, then web-download fallback)..."
$storeUpdated = $false
try {
    wsl.exe --update *>$null
    $storeUpdated = $true
} catch {
    Write-Output "Store-based update failed or unavailable. Trying web download..."
}

if (-not $storeUpdated) {
    try {
        # This pulls the official package directly (no Microsoft Store required)
        wsl.exe --update --web-download *>$null
    } catch {
        Write-Warning "Web download update attempt failed: $($_.Exception.Message)"
    }
}

# Re-check installed version
$wslVersion = Get-WSL-Version

if ([string]::IsNullOrWhiteSpace($wslVersion)) {
    Write-Warning "Couldn't detect WSL version programmatically. Printing raw 'wsl --version' output for reference:"
    try { wsl.exe --version } catch {}
    Write-Output "If you need to update manually, you can also try 'winget upgrade --id Microsoft.WSL -e' (if winget is available)."
    exit 0
}

Write-Output "Detected WSL version: $wslVersion"

$target = "2.5.10"
if (Compare-Version $wslVersion $target) {
    Write-Output "' WSL is up to date (>= $target)."
} else {
    Write-Warning "&�� WSL version ($wslVersion) is below $target."

    # Try winget (if available) before suggesting manual steps
    $hasWinget = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
    if ($hasWinget) {
        Write-Output "Attempting upgrade via winget..."
        try {
            winget source update | Out-Null
            winget upgrade --id Microsoft.WSL -e --accept-source-agreements --accept-package-agreements
        } catch {
            Write-Warning "winget upgrade failed: $($_.Exception.Message)"
        }
        # Check once more
        $wslVersion = Get-WSL-Version
        if ($wslVersion -and (Compare-Version $wslVersion $target)) {
            Write-Output "' WSL upgraded to $wslVersion (>= $target)."
            exit 0
        }
    }

    # Last resort: open Store if available (may be disabled on some systems)
    try {
        Start-Process "ms-windows-store://pdp/?productid=9P9TQF7MRM4R"
        Write-Output "Opened Microsoft Store page for Windows Subsystem for Linux."
    } catch {
        Write-Warning "Microsoft Store is unavailable on this system. Consider using:
1) 'wsl --update --web-download' (already attempted),
2) 'winget upgrade --id Microsoft.WSL -e' (if winget is available),
3) Or install the latest MSI package for WSL from the official source."
    }
}

Write-Output "Done."