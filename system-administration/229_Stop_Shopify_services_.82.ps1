# Script: Stop Shopify services .82
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 229

# Stop TCScheduler first, then TCServer, then show both statuses
$firstService  = "TCScheduler"
$secondService = "TCServer"
$timeoutSeconds = 300   # 5 minutes

function Stop-AndWaitService {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [int]$TimeoutSeconds = 300
    )

    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Output "Service '$Name' not found."
        return $false
    }

    if ($svc.Status -eq 'Stopped') {
        Write-Output "Service '$Name' is already Stopped."
        return $true
    }

    Write-Output "Stopping service '$Name'..."
    try {
        Stop-Service -Name $Name -Force -ErrorAction Stop
    } catch {
        Write-Output "Failed to stop '$Name': $($_.Exception.Message)"
        return $false
    }

    $sw = [Diagnostics.Stopwatch]::StartNew()
    do {
        Start-Sleep -Seconds 2
        $svc.Refresh()
    } while ($svc.Status -ne 'Stopped' -and $sw.Elapsed.TotalSeconds -lt $TimeoutSeconds)

    if ($svc.Status -eq 'Stopped') {
        Write-Output "Service '$Name' stopped successfully."
        return $true
    } else {
        Write-Output "Timeout waiting for '$Name' to stop. Current status: $($svc.Status)"
        return $false
    }
}

# 1) Stop TCScheduler
$firstStopped = Stop-AndWaitService -Name $firstService -TimeoutSeconds $timeoutSeconds

# 2) Stop TCServer only after TCScheduler is confirmed stopped
if ($firstStopped) {
    $secondStopped = Stop-AndWaitService -Name $secondService -TimeoutSeconds $timeoutSeconds
} else {
    Write-Output "Skipping stop of '$secondService' because '$firstService' did not stop cleanly."
    $secondStopped = $false
}

# 3) Show final status of both
Write-Output ""
Write-Output "Final service status:"
Get-Service -Name $firstService,$secondService -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType |
    Format-Table -AutoSize

if ($firstStopped -and $secondStopped) {
    Write-Output "Result: SUCCESS - Both services are stopped."
} else {
    Write-Output "Result: WARNING/FAIL - One or more services did not stop cleanly."
}
``