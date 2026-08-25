# Script: WinVerify
# Platform: Windows
# Description: WinVerifyTrust Signature Validation CVE-2013-3900 Mitigation (EnableCertPaddingCheck) #made by pstanczyk 2024-11-06
# NinjaOne Script ID: 106

# Define registry paths and key name
$regPaths = @(
    "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config",
    "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
)
$keyName = "EnableCertPaddingCheck"

foreach ($regPath in $regPaths) {
    # Check if the registry path exists; if not, create it
    if (!(Test-Path -Path $regPath)) {
        Write-Output "Registry path '$regPath' does not exist. Creating it now..."
        New-Item -Path $regPath -Force | Out-Null
    }
    
    # Check if the registry key exists
    if (!(Test-Path -Path "$regPath\$keyName")) {
        Write-Output "Registry key '$keyName' is not present in '$regPath'. Creating it now..."
        
        # Create the registry key and set its value to 1 (or any other default value you prefer)
        New-ItemProperty -Path $regPath -Name $keyName -Value 1 -PropertyType DWord -Force | Out-Null
        
        Write-Output "Registry key '$keyName' created successfully in '$regPath'."
    } else {
        Write-Output "Registry key '$keyName' already exists in '$regPath'."
    }
}


#made by pstanczyk 2024-11-06