# Script: PowerShell Script to Scan Open TCP Ports
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 171

# Define the target machine and port range
$target = "localhost"   # Change to IP or hostname as needed
$startPort = 1
$endPort = 3400

Write-Host "Scanning ports $startPort to $endPort on $target..."

for ($port = $startPort; $port -le $endPort; $port++) {
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $async = $connection.BeginConnect($target, $port, $null, $null)
        $wait = $async.AsyncWaitHandle.WaitOne(100, $false)
        if ($wait -and $connection.Connected) {
            Write-Host "Port $port is open"
            $connection.EndConnect($async)
            $connection.Close()
        }
    } catch {
        # Ignore connection errors
    }
}
