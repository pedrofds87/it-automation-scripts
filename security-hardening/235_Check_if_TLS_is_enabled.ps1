# Script: Check if TLS is enabled
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 235

$Protocols = @("TLS 1.0","TLS 1.1","TLS 1.2")

foreach ($Protocol in $Protocols) {

    Write-Host "========================="
    Write-Host "$Protocol"
    Write-Host "========================="

    foreach ($Role in @("Server","Client")) {

        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\$Role"

        Write-Host "`n$Role Settings:"

        if (Test-Path $Path) {

            $Settings = Get-ItemProperty -Path $Path

            Write-Host "Enabled:" $Settings.Enabled
            Write-Host "DisabledByDefault:" $Settings.DisabledByDefault

        } else {

            Write-Host "Registry key not found (OS defaults may apply)"
        }
    }

    Write-Host ""
}