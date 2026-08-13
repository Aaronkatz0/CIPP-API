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

    if ($Device.operatingSystem -ne 'Windows' -or [string]::IsNullOrWhiteSpace([string]$Device.azureADDeviceId)) {
        return [PSCustomObject]@{
            Fields          = $Fields
            HashData        = $HashData
            BitLockerKeyIds = $BitLockerKeyIds
        }
    }

    if ($Configuration.IncludeLAPS) {
        try {
            $LAPSResult = Get-CIPPLapsPassword -Device $Device.azureADDeviceId -TenantFilter $TenantFilter
            if ($LAPSResult -isnot [string] -and $LAPSResult.state -eq 'success') {
                $Fields.laps_account = $LAPSResult.accountName
                $Fields.laps_password = $LAPSResult.copyField
                $Fields.laps_backup_date = [string]$LAPSResult.backupDateTime
                $HashData.lapsBackupDateTime = [string]$LAPSResult.backupDateTime
            } else {
                $HashData.lapsBackupDateTime = $null
            }
        } catch {
            Write-Warning "Unable to retrieve LAPS data for $($Device.deviceName): $_"
            $HashData.lapsBackupDateTime = $null
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
        $HashData.bitLockerKeyIds = $BitLockerKeyIds
    }

    [PSCustomObject]@{
        Fields          = $Fields
        HashData        = $HashData
        BitLockerKeyIds = $BitLockerKeyIds
    }
}
