# Script: Microsoft Office ActiveX Controls Enabled Without Restrictions Or Prompting
# Platform: Windows
# Description: #pstanczyk 2024-11-08 user based this is for IT14
# NinjaOne Script ID: 124

# Define user SID and username
$userSID = "S-1-5-21-1970292086-3108915243-4053403418-9969"
$userName = "FITFOODS.LOCAL\emantovani"
$officeRegPath = "HKU:\$userSID\Software\Microsoft\Office"

# Log file for tracking
$logFile = "$env:TEMP\Office_ActiveX_Disable.log"

# Function for logging
Function Log {
    param ([string]$message)
    Add-Content -Path $logFile -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $message"
}

Log "Starting ActiveX control restrictions for user $userName ($userSID)."

# Function to update registry for ActiveX settings
Function UpdateActiveXSettings {
    param (
        [string]$regPath
    )
    
    # Check if the registry path exists
    if (Test-Path $regPath) {
        Log "Modifying ActiveX settings at $regPath..."
        
        # Disable or restrict ActiveX controls
        Set-ItemProperty -Path $regPath -Name "DisableAllActiveX" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "PromptBeforeActiveX" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "SafeForScriptingOnly" -Value 1 -Type DWord -Force
        
        Log "ActiveX controls have been restricted successfully."
    } else {
        Log "Registry path $regPath does not exist. Skipping."
    }
}

# Iterate through installed Office versions
$officeVersions = @("15.0", "16.0")  # Modify based on installed Office versions (e.g., Office 2013, 2016, 365)
foreach ($version in $officeVersions) {
    $activexRegPath = "$officeRegPath\$version\Common\Security"
    UpdateActiveXSettings -regPath $activexRegPath
}

Log "ActiveX control restriction script completed."
#pstanczyk 2024-11-08