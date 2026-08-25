# Script: Showing expired AD accounts (Run on DC)
# Platform: Windows
# Description: #pstanczyk
# NinjaOne Script ID: 195

Import-Module ActiveDirectory

$now = Get-Date
$maxFileTime = [datetime]::MaxValue.ToFileTime()

# Collect expired users
$expiredUsers = Get-ADUser -LDAPFilter "(&(objectCategory=person)(objectClass=user))" `
  -Properties msDS-UserPasswordExpiryTimeComputed, PasswordLastSet, PasswordNeverExpires, Enabled |
ForEach-Object {
    $raw = $_."msDS-UserPasswordExpiryTimeComputed"

    if ($_.Enabled -and
        -not $_.PasswordNeverExpires -and
        $raw -is [long] -and
        $raw -gt 0 -and
        $raw -lt $maxFileTime) {

        $expiry = [datetime]::FromFileTime($raw)

        if ($expiry -lt $now) {
            [pscustomobject]@{
                Name               = $_.Name
                SamAccountName     = $_.SamAccountName
                PasswordLastSet    = $_.PasswordLastSet
                PasswordExpiryDate = $expiry
            }
        }
    }
}

# If none found
if (-not $expiredUsers -or $expiredUsers.Count -eq 0) {
    Write-Output "No AD user accounts with expired passwords as of $($now.ToString('yyyy-MM-dd HH:mm'))."
    exit 0
}

# Format results as a plain text table
$table = $expiredUsers |
    Sort-Object PasswordExpiryDate |
    Format-Table Name, SamAccountName, PasswordLastSet, PasswordExpiryDate -AutoSize |
    Out-String

# Build simple message (no backticks, no weird escapes)
$message = "Expired AD user passwords as of $($now.ToString('yyyy-MM-dd HH:mm'))`r`n`r`n$table"

Write-Output $message

# ================================
# SEND TO SLACK (DIRECT WEBHOOK)
# ================================
# Force TLS 1.2 for outbound HTTPS (required by Slack)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$webhookUrl = "https://hooks.slack.com/services/YOUR_WEBHOOK_URL_HERE"

if ($expiredUsers -and $expiredUsers.Count -gt 0) {

    # Clean up table a bit
    $tableTrimmed = $table.Trim()

    # Build a Slack code fence (```), but without writing the backticks literally
    $codeFence = ([string][char]96) * 3   # three chars with ASCII 96 = `

    # Bold title + code block
    $slackText =
        "*Expired AD Password Report for $env:COMPUTERNAME*`n" +
        "$codeFence`n" +
        "$tableTrimmed`n" +
        "$codeFence"

    $payload = @{ text = $slackText } | ConvertTo-Json -Depth 6

    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType 'application/json'
    }
    catch {
        Write-Output "Slack post failed: $($_.Exception.Message)"
    }
}




# Non-zero so you can treat it as an alert if you want
exit 0
