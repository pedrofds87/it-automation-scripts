# Script: WinVerify 2
# Platform: Windows
# Description: pstanczyk
# NinjaOne Script ID: 151

# Define registry paths and key name
$regPaths = @(
    "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config",
    "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
)
$keyName = "EnableCertPaddingCheck"
$keyValue = 1  # Value to enable the setting

foreach ($regPath in $regPaths) {
    try {
        # Check if the registry path exists; if not, create it
        if (!(Test-Path -Path $regPath)) {
            Write-Output "Registry path '$regPath' does not exist. Creating it now..."
            New-Item -Path $regPath -Force | Out-Null
        }
        
        # Check if the registry key exists and set its value
        if (!(Get-ItemProperty -Path $regPath -Name $keyName -ErrorAction SilentlyContinue)) {
            Write-Output "Registry key '$keyName' is not present in '$regPath'. Creating and setting it now..."
            New-ItemProperty -Path $regPath -Name $keyName -Value $keyValue -PropertyType DWord -Force | Out-Null
            Write-Output "Registry key '$keyName' created successfully in '$regPath' with value $keyValue."
        } else {
            Write-Output "Registry key '$keyName' already exists in '$regPath'. Updating the value to $keyValue..."
            Set-ItemProperty -Path $regPath -Name $keyName -Value $keyValue -Force | Out-Null
            Write-Output "Registry key '$keyName' updated successfully in '$regPath' with value $keyValue."
        }
    } catch {
        Write-Error "Failed to create or update registry key in '$regPath': $_"
    }
}

#pstanczyk