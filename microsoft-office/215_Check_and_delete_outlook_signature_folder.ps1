# Script: Check and delete outlook signature folder
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 215

$signaturePath = Join-Path $env:APPDATA "Microsoft\Signatures"

Write-Host "Signature path: $signaturePath"
Write-Host ""

if (Test-Path $signaturePath) {
    Write-Host "Contents before deletion:" -ForegroundColor Yellow
    $before = Get-ChildItem -Path $signaturePath -Force -Recurse -ErrorAction SilentlyContinue

    if ($before) {
        $before | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
    } else {
        Write-Host "Folder exists, but it is already empty."
    }

    Write-Host ""
    Write-Host "Deleting all contents..." -ForegroundColor Cyan
    Get-ChildItem -Path $signaturePath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "Contents after deletion:" -ForegroundColor Green
    $after = Get-ChildItem -Path $signaturePath -Force -Recurse -ErrorAction SilentlyContinue

    if ($after) {
        $after | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
    } else {
        Write-Host "Folder is now empty."
    }
} else {
    Write-Host "Signature folder does not exist."
}