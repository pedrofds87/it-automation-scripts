# Script: Disable Untrusted Macro Execution in Excel
# Platform: Windows
# Description: #pstanczyk 2024-11-08
# NinjaOne Script ID: 125

# Define user SID and registry path
$userSID = "S-1-5-21-1970292086-3108915243-4053403418-9969"
$appName = "Excel"
$officeVersion = "16.0"
$registryPath = "HKU:\$userSID\Software\Microsoft\Office\$officeVersion\$appName\Security"

# Log file for tracking
$logFile = "$env:TEMP\Disable_Macro_Execution.log"

# Function for logging
Function Log {
    param ([string]$message)
    Add-Content -Path $logFile -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $message"
}

Log "Starting script to disable untrusted macro execution for $appName (Office $officeVersion)."

# Check if the registry path exists
if (Test-Path $registryPath) {
    Log "Modifying macro execution settings at $registryPath..."
    
    # Disable untrusted macro execution by setting VBAWarnings
    # 1 = Disable all macros without notification
    # 2 = Disable macros with notification
    # 3 = Disable macros except digitally signed macros
    # 4 = Enable all macros (not recommended)
    Set-ItemProperty -Path $registryPath -Name "VBAWarnings" -Value 2 -Type DWord -Force

    Log "Untrusted macro execution disabled for $appName (VBAWarnings set to 2)."
} else {
    Log "Registry path $registryPath does not exist. Skipping."
}

Log "Script completed."

#pstanczyk 2024-11-08