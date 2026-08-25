# Script: Stop SQLSERVERAGENT and MSSQLSERVER on .80
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 228

# Stop SQL Server Agent first, then SQL Server Engine, and confirm both stopped
$agentService = "SQLSERVERAGENT"
$engineService = "MSSQLSERVER"
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

# 1) Stop Agent first
$agentStopped = Stop-AndWaitService -Name $agentService -TimeoutSeconds $timeoutSeconds

# 2) Stop Engine second (only if Agent stopped successfully)
if ($agentStopped) {
    $engineStopped = Stop-AndWaitService -Name $engineService -TimeoutSeconds $timeoutSeconds
} else {
    Write-Output "Skipping stop of '$engineService' because '$agentService' did not stop cleanly."
    $engineStopped = $false
}

# 3) Show final status of both
Write-Output ""
Write-Output "Final service status:"
Get-Service -Name $agentService,$engineService -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType |
    Format-Table -AutoSize

# Exit code style for RMM (optional)
if ($agentStopped -and $engineStopped) {
    Write-Output "Result: SUCCESS - Both services are stopped."
} else {
    Write-Output "Result: WARNING/FAIL - One or more services did not stop cleanly."
}