# Script: Fix Permissions ECSPrintService
# Platform: Windows
# Description: #pstanczyk 2024-11-22
# NinjaOne Script ID: 136

# Define the path to the executable and the service name
$filePath = "c:\pwprintserver\printservice_new.exe"
$serviceName = "ECSPrintService"

# Check if the file exists
if (Test-Path $filePath) {
    Write-Output "File found: $filePath"
    
    # Backup current ACLs
    $backupAcl = Get-Acl $filePath
    $backupAcl | Set-Acl -Path "$filePath.bak"
    Write-Output "Permissions backed up to $filePath.bak"
    
    # Remove write permissions for 'Authenticated Users'
    Write-Output "Removing write permissions for 'Authenticated Users'..."
    icacls $filePath /remove "Authenticated Users"
    Write-Output "Write permissions for 'Authenticated Users' removed."

    # Verify the updated permissions
    $updatedAcl = Get-Acl $filePath
    Write-Output "Updated permissions:"
    $updatedAcl.Access | Format-Table -AutoSize
} else {
    Write-Output "File not found at the specified path: $filePath"
}

# Restart the associated service
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-Output "Restarting service: $serviceName..."
    Restart-Service -Name $serviceName -Force
    Write-Output "Service $serviceName restarted successfully."
} else {
    Write-Output "Service $serviceName not found."
}

Write-Output "Script completed. Permissions adjusted, and service restarted if applicable."

#pstanczyk 2024-11-22