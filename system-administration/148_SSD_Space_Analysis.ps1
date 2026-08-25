# Script: SSD Space Analysis
# Platform: Windows
# Description: #pstanczyk 2024-12-12
# NinjaOne Script ID: 148

# Define the drive to analyze
$Drive = "C:\"  # Change this to the desired drive or folder path

# Define the threshold for top large directories or files
$TopCount = 10

# Function to analyze space usage
function Get-FolderSize {
    param (
        [string]$Path
    )

    Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue |
    Where-Object { -not $_.PSIsContainer } |
    Measure-Object -Property Length -Sum | ForEach-Object {
        [PSCustomObject]@{
            Path  = $Path
            Size  = $_.Sum
        }
    }
}

# Gather folder size data
Write-Output "Analyzing disk usage on $Drive..."
$FolderSizes = Get-ChildItem -Path $Drive -Directory -ErrorAction SilentlyContinue |
    ForEach-Object {
        Get-FolderSize -Path $_.FullName
    } |
    Sort-Object -Property Size -Descending |
    Select-Object -First $TopCount

# Gather largest files
$LargestFiles = Get-ChildItem -Path $Drive -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object -Property Length -Descending |
    Select-Object -First $TopCount @{Name="Size (MB)"; Expression={"{0:N2}" -f ($_.Length / 1MB)}}, FullName

# Display results
Write-Output "\nTop $TopCount largest directories by size:" | Out-String
$FolderSizes | Format-Table -Property Path, @{Name="Size (GB)"; Expression={"{0:N2}" -f ($_.Size / 1GB)}}

Write-Output "\nTop $TopCount largest files by size:" | Out-String
$LargestFiles | Format-Table -Property FullName, Size

Write-Output "Analysis completed."

#pstanczyk 2024-12-12