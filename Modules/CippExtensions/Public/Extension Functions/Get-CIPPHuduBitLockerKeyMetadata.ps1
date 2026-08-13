function Get-CIPPHuduBitLockerKeyMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter
    )

    try {
        $CachedKeys = @(
            Get-CIPPDbItem -TenantFilter $TenantFilter -Type 'BitlockerKeys' |
                Where-Object { $_.RowKey -notlike '*-Count' } |
                ForEach-Object {
                    if ($_.Data -is [string]) {
                        $_.Data | ConvertFrom-Json
                    } else {
                        $_.Data
                    }
                }
        )

        if ($CachedKeys.Count -gt 0) {
            return $CachedKeys
        }
    } catch {
        Write-Warning "Unable to read cached BitLocker key metadata for $TenantFilter. Falling back to Microsoft Graph. Error: $_"
    }

    try {
        return @(
            New-GraphGetRequest -uri 'https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys?$select=id,createdDateTime,volumeType,deviceId' -tenantid $TenantFilter
        )
    } catch {
        Write-Warning "Unable to retrieve BitLocker key metadata for $TenantFilter. Error: $_"
        return @()
    }
}
