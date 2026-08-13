<#
.SYNOPSIS
    Retrieves BitLocker recovery keys for a managed device from Microsoft Graph API.

.DESCRIPTION
    This function queries the Microsoft Graph API to retrieve BitLocker recovery keys associated with
    a specified device. When KeyId is supplied, the function retrieves those keys directly and skips
    the device-level recovery key lookup.
.PARAMETER Device
    The ID of the device for which to retrieve BitLocker recovery keys.

.PARAMETER TenantFilter
    The tenant ID to filter the request to the appropriate tenant.

.PARAMETER KeyId
    Optional recovery key ID or IDs to retrieve directly. This avoids an additional Graph lookup when
    key IDs are already known from cached BitLocker metadata.

.PARAMETER APIName
    The name of the API operation for logging purposes. Defaults to 'Get BitLocker key'.

.PARAMETER Headers
    The headers to include in the request, typically used for authentication and logging.

.OUTPUTS
    Array of PSCustomObject with properties:
    - resultText: Formatted string containing the key ID and key value
    - copyField: The raw key value
    - keyId: The BitLocker recovery key ID
    - createdDateTime: The recovery key creation date when available
    - volumeType: The BitLocker volume type when available
    - state: Status of the operation ('success')

    Or a string message if no keys are found.
#>

function Get-CIPPBitLockerKey {
    [CmdletBinding()]
    param (
        $Device,
        $TenantFilter,
        [string[]]$KeyId,
        $APIName = 'Get BitLocker key',
        $Headers
    )

    try {
        if ($KeyId) {
            $GraphRequest = foreach ($RecoveryKeyId in $KeyId) {
                $BitLockerKeyObject = New-GraphGetRequest -uri "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys/$($RecoveryKeyId)?`$select=key" -tenantid $TenantFilter
                [PSCustomObject]@{
                    resultText      = "Id: $($RecoveryKeyId) Key: $($BitLockerKeyObject.key)"
                    copyField       = $BitLockerKeyObject.key
                    keyId           = $RecoveryKeyId
                    createdDateTime = $null
                    volumeType      = $null
                    state           = 'success'
                }
            }
        } else {
            $GraphRequest = New-GraphGetRequest -uri "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys?`$filter=deviceId eq '$($Device)'" -tenantid $TenantFilter |
                ForEach-Object {
                    $BitLockerKeyObject = New-GraphGetRequest -uri "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys/$($_.id)?`$select=key" -tenantid $TenantFilter
                    [PSCustomObject]@{
                        resultText      = "Id: $($_.id) Key: $($BitLockerKeyObject.key)"
                        copyField       = $BitLockerKeyObject.key
                        keyId           = $_.id
                        createdDateTime = $_.createdDateTime
                        volumeType      = $_.volumeType
                        state           = 'success'
                    }
                }
        }

        if (@($GraphRequest).Count -eq 0) {
            Write-LogMessage -headers $Headers -API $APIName -message "No BitLocker recovery keys found for $($Device)" -Sev Info -tenant $TenantFilter
            return "No BitLocker recovery keys found for $device"
        }
        Write-LogMessage -headers $Headers -API $APIName -message "Retrieved BitLocker recovery keys for $($Device)" -Sev Info -tenant $TenantFilter
        return $GraphRequest
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        $Result = "Could not retrieve BitLocker recovery key for $($Device). Error: $($ErrorMessage.NormalizedError)"
        Write-LogMessage -headers $Headers -API $APIName -message $Result -Sev Error -tenant $TenantFilter -LogData $ErrorMessage
        throw $Result
    }
}
