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
        return [PSCustomObject]@{ Fields = $Fields; Success = $true }
    }

    try {
        $BitLockerKeys = @(
            Get-CIPPBitLockerKey -Device $Device.azureADDeviceId -TenantFilter $TenantFilter -KeyId $KeyId |
                Where-Object { $_ -isnot [string] -and $_.state -eq 'success' } |
                Sort-Object keyId
        )

        $Success = $BitLockerKeys.Count -eq $KeyId.Count
        if ($Success) {
            $Fields.bitlocker_recovery_keys = ($BitLockerKeys | ForEach-Object { "$($_.keyId): $($_.copyField)" }) -join "`n"
        } else {
            Write-Warning "BitLocker recovery key retrieval was incomplete for $($Device.deviceName)."
        }

        return [PSCustomObject]@{ Fields = $Fields; Success = $Success }
    } catch {
        Write-Warning "Unable to retrieve BitLocker recovery keys for $($Device.deviceName): $_"
        return [PSCustomObject]@{ Fields = $Fields; Success = $false }
    }
}
