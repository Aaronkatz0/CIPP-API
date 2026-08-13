function Get-CIPPHuduDeviceSecretData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Device,
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter,
        [Parameter(Mandatory = $true)]
        $Configuration,
        [object[]]$BitLockerKeyMetadata = @()
    )

    $Fields = @{}
    $HashData = [ordered]@{}
    $BitLockerKeyIds = @()
    $Success = $true

    if ($Device.operatingSystem -ne 'Windows' -or [string]::IsNullOrWhiteSpace([string]$Device.azureADDeviceId)) {
        return [PSCustomObject]@{
            Fields          = $Fields
            HashData        = $HashData
            BitLockerKeyIds = $BitLockerKeyIds
            Success         = $true
        }
    }

    if ($Configuration.IncludeLAPS) {
        try {
            $LAPSResult = Get-CIPPLapsPassword -Device $Device.azureADDeviceId -TenantFilter $TenantFilter
            if ($LAPSResult -isnot [string] -and $LAPSResult.state -eq 'success') {
                $Fields.laps_account = $LAPSResult.accountName
                $Fields.laps_password = $LAPSResult.copyField
                $Fields.laps_backup_date = [string]$LAPSResult.backupDateTime
                $HashData.lapsAccount = $LAPSResult.accountName
                $HashData.lapsBackupDateTime = [string]$LAPSResult.backupDateTime
            } elseif ([string]$LAPSResult -like 'No LAPS password found*') {
                $Fields.laps_account = ''
                $Fields.laps_password = ''
                $Fields.laps_backup_date = ''
                $HashData.lapsAccount = $null
                $HashData.lapsBackupDateTime = $null
            } else {
                $Success = $false
            }
        } catch {
            Write-Warning "Unable to retrieve LAPS data for $($Device.deviceName): $_"
            $Success = $false
        }
    }

    if ($Configuration.IncludeBitLocker) {
        $DeviceBitLockerKeys = @(
            $BitLockerKeyMetadata |
                Where-Object { $_.deviceId -eq $Device.azureADDeviceId } |
                Sort-Object id
        )
        $BitLockerKeyIds = @($DeviceBitLockerKeys.id)
        $Fields.bitlocker_key_ids = $BitLockerKeyIds -join "`n"
        if ($BitLockerKeyIds.Count -eq 0) {
            $Fields.bitlocker_recovery_keys = ''
        }
        $HashData.bitLockerKeyIds = $BitLockerKeyIds
    }

    [PSCustomObject]@{
        Fields          = $Fields
        HashData        = $HashData
        BitLockerKeyIds = $BitLockerKeyIds
        Success         = $Success
    }
}
