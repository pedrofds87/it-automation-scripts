# Script: install ASP.NET Core Runtime 8.0.21
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 181

<# 
  Upgrade ASP.NET Core shared framework (Microsoft.AspNetCore.App) to 8.0.21
  - Prefers winget; falls back to dotnet-install.ps1 from Microsoft.
  - Verifies install.
  - Optional clean-up of old 8.0.x patch folders (disabled by default).
#>

[CmdletBinding()]
param(
  [string]$TargetVersion = "8.0.21",
  [switch]$CleanupOldPatches  # add -CleanupOldPatches to remove older 8.0.x after success
)

function Require-Admin {
  $isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $isAdmin) { Write-Error "Please run PowerShell as Administrator."; exit 1 }
}

function Get-AspNetSharedRoot {
  $dotnetRoot = Join-Path ${env:ProgramFiles} "dotnet"
  $aspnetRoot = Join-Path $dotnetRoot "shared\Microsoft.AspNetCore.App"
  if (-not (Test-Path $aspnetRoot)) {
    Write-Verbose "ASP.NET Core shared path not found at $aspnetRoot"
  }
  return $aspnetRoot
}

function Get-InstalledAspNetVersions {
  $root = Get-AspNetSharedRoot
  if (Test-Path $root) {
    (Get-ChildItem $root -Directory | Select-Object -ExpandProperty Name)
  } else { @() }
}

function Install-WithWinget {
  param([string]$version)
  try {
    $null = winget --version 2>$null
  } catch {
    return $false
  }
  Write-Host "Using winget to install ASP.NET Core Runtime $version ..." -ForegroundColor Cyan
  # Package IDs commonly used by Microsoft for ASP.NET Core Runtime 8
  $cmd = "winget install --id Microsoft.DotNet.AspNetCoreRuntime.8 --version $version --accept-package-agreements --accept-source-agreements --silent"
  $proc = Start-Process powershell -ArgumentList "-NoLogo -NoProfile -Command `$ErrorActionPreference='Stop'; $cmd" -Wait -PassThru
  return ($proc.ExitCode -eq 0)
}

function Install-WithDotnetInstall {
  param([string]$version)
  $script = Join-Path $env:TEMP "dotnet-install.ps1"
  $url    = "https://dot.net/v1/dotnet-install.ps1"
  Write-Host "Falling back to dotnet-install.ps1 (runtime=aspnetcore, version=$version) ..." -ForegroundColor Yellow
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $script
  & $script -Runtime "aspnetcore" -Version $version -InstallDir (Join-Path ${env:ProgramFiles} "dotnet") -NoPath
  if ($LASTEXITCODE -ne 0) { return $false }
  return $true
}

function Verify-Installed {
  param([string]$version)
  try {
    $runtimes = (& dotnet --list-runtimes) 2>$null
  } catch {
    $runtimes = @()
  }
  $hasTarget = $runtimes | Where-Object { $_ -match "Microsoft.AspNetCore.App\s+$([regex]::Escape($version))" }
  if ($hasTarget) {
    Write-Host "Verified: Microsoft.AspNetCore.App $version is installed." -ForegroundColor Green
    return $true
  } else {
    # Fallback check via folder presence
    $installed = Get-InstalledAspNetVersions
    if ($installed -contains $version) {
      Write-Host "Verified by folder: Microsoft.AspNetCore.App $version present." -ForegroundColor Green
      return $true
    }
  }
  return $false
}

function Cleanup-Old-8Patch {
  param([string]$version)
  $root = Get-AspNetSharedRoot
  if (-not (Test-Path $root)) { return }
  $vTarget = [version]$version
  $old = Get-ChildItem $root -Directory |
         Where-Object {
            $_.Name -like "8.0.*" -and ([version]$_.Name) -lt $vTarget
         }
  if ($old.Count -eq 0) {
    Write-Host "No older 8.0.x patches to remove." -ForegroundColor DarkGray
    return
  }
  Write-Host "Removing older 8.0.x patch folders:" -ForegroundColor Yellow
  $old | ForEach-Object {
    Write-Host "  Deleting $($_.FullName)"
    try { Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop } catch {
      Write-Warning "  Could not delete $($_.FullName): $($_.Exception.Message)"
    }
  }
}

# --- Main ---
Require-Admin

$installed = Get-InstalledAspNetVersions
if ($installed -contains $TargetVersion) {
  Write-Host "Target version $TargetVersion already installed." -ForegroundColor Green
} else {
  if (-not (Install-WithWinget -version $TargetVersion)) {
    if (-not (Install-WithDotnetInstall -version $TargetVersion)) {
      Write-Error "Installation failed using both winget and dotnet-install.ps1."
      exit 1
    }
  }
}

if (-not (Verify-Installed -version $TargetVersion)) {
  Write-Error "Could not verify Microsoft.AspNetCore.App $TargetVersion after install."
  exit 1
}

if ($CleanupOldPatches) {
  Cleanup-Old-8Patch -version $TargetVersion
}

Write-Host "Done." -ForegroundColor Green
