# Script: Insecure Windows Service Permissions 
# Platform: Windows
# Description: Path : c:\program files (x86)\pwprintserver\printservice_new.exe Used by services : ECSPrintService File write allowed for groups : Users (S-1-5-32-545) Full control of directory allowed for groups :
# NinjaOne Script ID: 168

# Define paths
$FilePath = "C:\Program Files (x86)\pwprintserver\printservice_new.exe"
$DirectoryPath = "C:\Program Files (x86)\pwprintserver"

# Define the insecure group (Users)
$UsersGroup = 'BUILTIN\Users'

# Backup current ACLs (Optional)
$BackupFileACL = Get-Acl $FilePath
$BackupDirACL = Get-Acl $DirectoryPath
$BackupFileACL | Export-Clixml -Path "C:\Backup_PrintService_File_ACL.xml"
$BackupDirACL | Export-Clixml -Path "C:\Backup_PrintService_Dir_ACL.xml"

# Ensure the file exists before modifying ACLs
if (Test-Path $FilePath) {
    $FileAcl = Get-Acl $FilePath

    # Remove write access for "Users" group from the executable file
    $FileAcl.Access | Where-Object { $_.IdentityReference -eq $UsersGroup -and $_.FileSystemRights -match "Write" } | ForEach-Object {
        $FileAcl.RemoveAccessRule($_)
    }

    Set-Acl -Path $FilePath -AclObject $FileAcl
    Write-Host "Restricted 'Write' permissions on ${FilePath}"
} else {
    Write-Host "File not found: ${FilePath}, skipping ACL modification."
}

# Ensure the directory exists before modifying ACLs
if (Test-Path $DirectoryPath) {
    $DirAcl = Get-Acl $DirectoryPath

    if ($DirAcl -ne $null) {
        # Remove FullControl permissions for "Users" group from the directory
        $DirAcl.Access | Where-Object { $_.IdentityReference -eq $UsersGroup -and $_.FileSystemRights -match "FullControl" } | ForEach-Object {
            $DirAcl.RemoveAccessRule($_)
        }

        Set-Acl -Path $DirectoryPath -AclObject $DirAcl
        Write-Host "Removed 'Full Control' from ${DirectoryPath}"

        # Ensure "Users" have only Read & Execute, not FullControl
        $NewRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users","ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")
        $DirAcl.AddAccessRule($NewRule)
        Set-Acl -Path $DirectoryPath -AclObject $DirAcl
    } else {
        Write-Host "Warning: Failed to retrieve ACL for ${DirectoryPath}, skipping ACL modification."
    }
} else {
    Write-Host "Directory not found: ${DirectoryPath}, skipping ACL modification."
}

# Verify changes
Write-Host "Updated permissions for ${FilePath}:"
Get-Acl $FilePath | Format-List

Write-Host "Updated permissions for ${DirectoryPath}:"
Get-Acl $DirectoryPath | Format-List
