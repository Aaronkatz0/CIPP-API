function Get-CIPPHuduBitLockerRecoveryFields {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Device,
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter,
        [string[]]$KeyId
    )

    $Fields = @{}
    if (-not $KeyId -or $KeyId.Count -eq 0) {
        return $Fields
    }

    try {
        $BitLockerKeys = @(
            Get-CIPPBitLockerKey -Device $Device.azureADDeviceId -TenantFilter $TenantFilter -KeyId $KeyId |
                Where-Object { $_ -isnot [string] -and $_.state -eq 'success' } |
                Sort-Object keyId
        )

        if ($BitLockerKeys.Count -gt 0) {
            $Fields.bitlocker_recovery_keys = ($BitLockerKeys | ForEach-Object { "$($_.keyId): $($_.copyField)" }) -join "`n"
        }
    } catch {
        Write-Warning "Unable to retrieve BitLocker recovery keys for $($Device.deviceName): $_"
    }

    return $Fields
}
