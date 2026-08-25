# Script: Script to disable TLS 1.0 and 1.1
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 218

$protocols = @("TLS 1.0","TLS 1.1")

foreach ($protocol in $protocols) {
    foreach ($role in @("Client","Server")) {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$protocol\$role"
        New-Item -Path $path -Force | Out-Null
        New-ItemProperty -Path $path -Name Enabled -PropertyType DWord -Value 0 -Force | Out-Null
        New-ItemProperty -Path $path -Name DisabledByDefault -PropertyType DWord -Value 1 -Force | Out-Null
    }
}

Write-Host "TLS 1.0 and TLS 1.1 disabled. Reboot required."