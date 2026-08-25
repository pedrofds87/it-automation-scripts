# Script: Check signature (test)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 216

Write-Host "=== Outlook Signature Validation ===" -ForegroundColor Cyan
Write-Host ""

# Signature folder
$signaturePath = Join-Path $env:APPDATA "Microsoft\Signatures"
Write-Host "Signature folder:" $signaturePath -ForegroundColor Yellow

if (Test-Path $signaturePath) {
    $items = Get-ChildItem -Path $signaturePath -Force -Recurse -ErrorAction SilentlyContinue
    if ($items) {
        Write-Host "Contents found in signature folder:" -ForegroundColor Red
        $items | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
    } else {
        Write-Host "Signature folder exists and is empty." -ForegroundColor Green
    }
} else {
    Write-Host "Signature folder does not exist." -ForegroundColor Green
}

Write-Host ""

# Policy key
$policyPath = "HKCU:\Software\Policies\Microsoft\Office\16.0\Common\MailSettings"
Write-Host "Checking policy key:" $policyPath -ForegroundColor Yellow

if (Test-Path $policyPath) {
    $policy = Get-ItemProperty -Path $policyPath -ErrorAction SilentlyContinue
    if ($null -ne $policy.DisableSignatures) {
        Write-Host "DisableSignatures policy found: $($policy.DisableSignatures)" -ForegroundColor Green
    } else {
        Write-Host "Policy key exists, but DisableSignatures is missing." -ForegroundColor Red
    }
} else {
    Write-Host "Policy key not found." -ForegroundColor Red
}

Write-Host ""

# Default assigned signatures
$mailSettingsPath = "HKCU:\Software\Microsoft\Office\16.0\Common\MailSettings"
Write-Host "Checking assigned default signatures:" $mailSettingsPath -ForegroundColor Yellow

if (Test-Path $mailSettingsPath) {
    $mailSettings = Get-ItemProperty -Path $mailSettingsPath -ErrorAction SilentlyContinue

    $newSig = $mailSettings.NewSignature
    $replySig = $mailSettings.ReplySignature

    if ([string]::IsNullOrWhiteSpace($newSig)) {
        Write-Host "NewSignature is not assigned." -ForegroundColor Green
    } else {
        Write-Host "NewSignature still assigned: $newSig" -ForegroundColor Red
    }

    if ([string]::IsNullOrWhiteSpace($replySig)) {
        Write-Host "ReplySignature is not assigned." -ForegroundColor Green
    } else {
        Write-Host "ReplySignature still assigned: $replySig" -ForegroundColor Red
    }
} else {
    Write-Host "MailSettings key not found." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Running gpresult /r ..." -ForegroundColor Yellow
Write-Host ""

gpresult /r

Write-Host ""
Write-Host "=== Validation Complete ===" -ForegroundColor Cyan