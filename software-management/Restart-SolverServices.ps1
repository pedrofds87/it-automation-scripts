# Restart-SolverServices.ps1
# Restarts Solver Report Service (ReportService), Solver Report Publishing Service (PublishingService), Solver Report Service (MaintenanceService)
# Logs to: C:\ProgramData\Solver\ServiceRestart.log

$ErrorActionPreference = "Stop"

$logDir  = "C:\ProgramData\Solver"
$logFile = Join-Path $logDir "ServiceRestart.log"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Log($msg) {
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line
}

$servicesInOrder = @(
    "MaintenanceService",
    "PublishingService",
    "ReportService"
)

Log "=== Restart run starting ==="

foreach ($svcName in $servicesInOrder) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction Stop
        Log "Service [$svcName] current status: $($svc.Status)"

        if ($svc.Status -eq "Running") {
            Log "Restarting [$svcName]..."
            Restart-Service -Name $svcName -Force -ErrorAction Stop
        } else {
            Log "Service [$svcName] not running. Starting..."
            Start-Service -Name $svcName -ErrorAction Stop
        }

        $svc.WaitForStatus("Running", (New-TimeSpan -Seconds 60))
        $svc2 = Get-Service -Name $svcName
        Log "Service [$svcName] new status: $($svc2.Status)"
    }
    catch {
        Log "ERROR restarting [$svcName]: $($_.Exception.Message)"
    }
}

Log "=== Restart run completed ==="
