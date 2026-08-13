function Add-CIPPHuduDeviceSecretLayoutFields {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$AssetLayoutId,
        [Parameter(Mandatory = $true)]
        $Configuration
    )

    if ($Configuration.IncludeLAPS) {
        $null = Add-HuduAssetLayoutField -AssetLayoutId $AssetLayoutId -Label 'LAPS Account' -FieldType 'Text'
        $null = Add-HuduAssetLayoutField -AssetLayoutId $AssetLayoutId -Label 'LAPS Password' -FieldType 'Password'
        $null = Add-HuduAssetLayoutField -AssetLayoutId $AssetLayoutId -Label 'LAPS Backup Date' -FieldType 'Text'
    }

    if ($Configuration.IncludeBitLocker) {
        $null = Add-HuduAssetLayoutField -AssetLayoutId $AssetLayoutId -Label 'BitLocker Recovery Keys' -FieldType 'Password'
        $null = Add-HuduAssetLayoutField -AssetLayoutId $AssetLayoutId -Label 'BitLocker Key IDs' -FieldType 'Text'
    }
}
