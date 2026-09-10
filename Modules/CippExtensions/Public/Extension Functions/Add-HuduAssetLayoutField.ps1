function Add-HuduAssetLayoutField {
    Param(
        $AssetLayoutId,
        $Label = 'Microsoft 365',
        $FieldType = 'RichText',
        $Position = 0,
        $ShowInList = $false
    )

    $M365Field = @{
        position     = $Position
        label        = $Label
        field_type   = $FieldType
        show_in_list = $ShowInList
        required     = $false
        expiration   = $false
    }

    $AssetLayout = Get-HuduAssetLayouts -LayoutId $AssetLayoutId

    $AssetLayoutFields = [System.Collections.Generic.List[object]]::new()
    $ExistingField = $AssetLayout.fields | Where-Object { $_.label -eq $Label } | Select-Object -First 1
    if ($ExistingField) {
        foreach ($Property in $ExistingField.PSObject.Properties) { $M365Field[$Property.Name] = $Property.Value }
        $M365Field.position = $Position
        $M365Field.field_type = $FieldType
        $M365Field.show_in_list = $ShowInList
    }

    $RemainingFields = @($AssetLayout.fields | Where-Object { $_.label -ne $Label } | Sort-Object position)
    $InsertAt = [Math]::Min([Math]::Max(0, [int]$Position), $RemainingFields.Count)
    for ($Index = 0; $Index -le $RemainingFields.Count; $Index++) {
        if ($Index -eq $InsertAt) { $AssetLayoutFields.Add($M365Field) }
        if ($Index -lt $RemainingFields.Count) {
            $Field = $RemainingFields[$Index]
            $LayoutField = @{}
            if ($Field -is [System.Collections.IDictionary]) {
                foreach ($Key in $Field.Keys) { $LayoutField[$Key] = $Field[$Key] }
            } else {
                foreach ($Property in $Field.PSObject.Properties) { $LayoutField[$Property.Name] = $Property.Value }
            }
            $AssetLayoutFields.Add($LayoutField)
        }
    }

    for ($Index = 0; $Index -lt $AssetLayoutFields.Count; $Index++) {
        $AssetLayoutFields[$Index].position = $Index
    }

    $CurrentField = $AssetLayout.fields | Where-Object { $_.label -eq $Label } | Select-Object -First 1
    if ($CurrentField -and [int]$CurrentField.position -eq $InsertAt -and
        [string]$CurrentField.field_type -eq $FieldType -and
        [bool]$CurrentField.show_in_list -eq [bool]$ShowInList) {
        return $AssetLayout
    }

    Set-HuduAssetLayout -Id $AssetLayoutId -Fields $AssetLayoutFields
}
