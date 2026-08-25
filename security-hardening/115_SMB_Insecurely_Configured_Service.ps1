# Script: SMB Insecurely Configured Service
# Platform: Windows
# Description: #pstanczyk 2024-11-07 PowerShell Script to Remove Insecure Permissions on Services
# NinjaOne Script ID: 115

# Define an array of services with insecure permissions
$services = @(
    "DeepETPService", 
    "DeepMgmtService", 
    "DeepNetworkService", 
    "DeepStaticService"
)

# Define the permissions to remove
$permissionsToRemove = "DC", "WD", "WO"

# Function to remove insecure permissions from a specified service
function Remove-InsecureServicePermissions {
    param (
        [string]$serviceName,
        [string[]]$permissions
    )

    # Get the service ACL
    $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName"
    $acl = Get-Acl -Path $servicePath

    # Remove the specified permissions for the 'Everyone' group
    foreach ($accessRule in $acl.Access) {
        if ($accessRule.IdentityReference -eq "Everyone" -and $permissions -contains $accessRule.AccessControlType) {
            $acl.RemoveAccessRule($accessRule)
        }
    }

    # Set the updated ACL
    Set-Acl -Path $servicePath -AclObject $acl
}

# Loop through each service and apply the permission changes
foreach ($service in $services) {
    Write-Output "Removing insecure permissions from service: $service"
    Remove-InsecureServicePermissions -serviceName $service -permissions $permissionsToRemove
    Write-Output "Permissions updated for $service."
}

Write-Output "All specified services have been updated."

#pstanczyk 2024-11-07