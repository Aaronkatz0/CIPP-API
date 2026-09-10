BeforeAll {
    . "$PSScriptRoot/../../Modules/CippExtensions/Public/Hudu/Get-HuduBitLockerKeySlots.ps1"
    . "$PSScriptRoot/../../Modules/CippExtensions/Public/Hudu/Get-HuduBitLockerSyncFields.ps1"
    $source = Get-Content -Raw "$PSScriptRoot/../../Modules/CippExtensions/Public/Hudu/Invoke-HuduExtensionSync.ps1"
    $start = $source.IndexOf('                    $DeviceAssetFields = @{')
    $end = $source.IndexOf('                    $NewHash = Get-StringHash', $start)
    $credentialBlock = [scriptblock]::Create($source.Substring($start, $end - $start))
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)
    $updateIf = $ast.Find({ param($node)
        $node -is [System.Management.Automation.Language.IfStatementAst] -and
        $node.Clauses[0].Item1.Extent.Text -like '*!$ExistingAsset -or $ExistingAsset.Hash*'
    }, $true)
    $updateCondition = [scriptblock]::Create($updateIf.Clauses[0].Item1.Extent.Text)
    function Get-CIPPLapsPassword { }
    function Get-CIPPBitLockerKey { }
}

Describe 'Hudu missing credential recovery' {
    BeforeEach {
        $Configuration = @{ IncludeLAPS = $false; IncludeBitLocker = $false }
        $Device = @{ operatingSystem = 'Windows'; azureADDeviceId = 'device-1' }
        $HuduDevice = @{ id = 1; fields = @(
            @{ label = 'LAPS Account'; value = 'Administrator' }
            @{ label = 'LAPS Backup Date'; value = '2026-09-07T00:00:00Z' }
            @{ label = 'BitLocker OS Drive 1 Key ID'; value = 'key-1' }
        ) }
        $LAPSMetadataAvailable = $true
        $LAPSMetadataByDeviceId = @{ 'device-1' = @{ lastBackupDateTime = '2026-09-07T00:00:00Z' } }
        $BitLockerMetadataAvailable = $true
        $BitLockerKeyMetadata = @(@{ deviceId = 'device-1'; id = 'key-1'; volumeType = 1 })
        $ExistingAsset = @{ Hash = 'unchanged' }
        $NewHash = 'unchanged'
        Mock Get-CIPPLapsPassword { @{ state = 'success'; accountName = 'Administrator'; copyField = 'test-password'; backupDateTime = '2026-09-07T00:00:00Z' } }
        Mock Get-CIPPBitLockerKey { @{ state = 'success'; keyId = 'key-1'; copyField = 'test-key' } }
    }

    It 'saves a recovered LAPS password when metadata and cached hash match' {
        $Configuration.IncludeLAPS = $true
        . $credentialBlock
        $DeviceAssetFields.laps_password | Should -Be 'test-password'
        (& $updateCondition) | Should -BeTrue
        Should -Invoke Get-CIPPLapsPassword -Times 1 -Exactly
    }

    It 'retrieves and saves missing BitLocker keys when key IDs and hash match' {
        $Configuration.IncludeBitLocker = $true
        . $credentialBlock
        $DeviceAssetFields.bitlocker_os_drive_1_recovery_key | Should -Be 'test-key'
        (& $updateCondition) | Should -BeTrue
        Should -Invoke Get-CIPPBitLockerKey -Times 1 -Exactly
    }

    It 'does not retrieve unchanged credentials that are already present' {
        $Configuration.IncludeLAPS = $true
        $Configuration.IncludeBitLocker = $true
        $HuduDevice.fields += @{ label = 'LAPS Password'; value = 'present' }
        $HuduDevice.fields += @{ label = 'BitLocker OS Drive 1 Recovery Key'; value = 'present' }
        . $credentialBlock
        (& $updateCondition) | Should -BeFalse
        Should -Invoke Get-CIPPLapsPassword -Times 0 -Exactly
        Should -Invoke Get-CIPPBitLockerKey -Times 0 -Exactly
    }
}
