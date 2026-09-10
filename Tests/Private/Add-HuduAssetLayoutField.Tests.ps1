BeforeAll {
    . "$PSScriptRoot/../../Modules/CippExtensions/Public/Extension Functions/Add-HuduAssetLayoutField.ps1"
    function Get-HuduAssetLayouts { param($LayoutId) $script:Layout }
    function Set-HuduAssetLayout {
        param($Id, $Fields)
        foreach ($field in $Fields) { $field.Remove('required') }
        $script:SentFields = $Fields
    }
}
Describe 'Hudu layout field normalization' {
    It 'copies object and dictionary fields and inserts at the requested position' {
        $script:Layout = @{ fields = @(
            [pscustomobject]@{ id = 1; label = 'Serial'; position = 0; required = $false; field_type = 'Text' }
            @{ id = 2; label = 'Notes'; position = 1; required = $false; field_type = 'RichText' }
        ) }
        Add-HuduAssetLayoutField -AssetLayoutId 10 -Label 'LAPS Password' -FieldType 'Password' -Position 1
        $script:SentFields.Count | Should -Be 3
        $script:SentFields[0].id | Should -Be 1
        $script:SentFields[1].field_type | Should -Be 'Password'
        $script:SentFields[2].position | Should -Be 2
        $script:Layout.fields[0].position | Should -Be 0
        $script:Layout.fields[1].position | Should -Be 1
    }
    It 'does not update a layout when field type and position already match' {
        $script:SentFields = $null
        $script:Layout = @{ fields = @([pscustomobject]@{ label = 'LAPS Password'; position = 0; field_type = 'Password'; show_in_list = $false }) }
        Add-HuduAssetLayoutField -AssetLayoutId 10 -Label 'LAPS Password' -FieldType Password -Position 0
        $script:SentFields | Should -BeNullOrEmpty
    }

    It 'moves the LAPS account above the password and makes it copyable' {
        $script:Layout = @{ fields = @(
            [pscustomobject]@{ id = 1; label = 'LAPS Password'; position = 0; field_type = 'Password'; show_in_list = $false }
            [pscustomobject]@{ id = 2; label = 'LAPS Account'; position = 1; field_type = 'Text'; show_in_list = $false }
        ) }
        Add-HuduAssetLayoutField -AssetLayoutId 10 -Label 'LAPS Account' -FieldType Email -Position 0
        $script:SentFields[0].label | Should -Be 'LAPS Account'
        $script:SentFields[0].field_type | Should -Be 'Email'
        $script:SentFields[1].label | Should -Be 'LAPS Password'
    }
}
