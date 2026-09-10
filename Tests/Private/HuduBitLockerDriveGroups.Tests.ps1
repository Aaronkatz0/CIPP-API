BeforeAll {
    . "$PSScriptRoot/../../Modules/CippExtensions/Public/Hudu/Get-HuduBitLockerKeySlots.ps1"
    . "$PSScriptRoot/../../Modules/CippExtensions/Public/Hudu/Get-HuduBitLockerSyncFields.ps1"
    function Get-CIPPBitLockerKey { }
}
Describe 'BitLocker drive groups' {
    BeforeEach {
        $metadata = @(@{ id = 'a'; volumeType = 1 }, @{ id = 'b'; volumeType = 'fixedDataVolume' }, @{ id = 'c'; volumeType = 'operatingSystemVolume' })
        Mock Get-CIPPBitLockerKey {
            @(@{ keyId = 'c'; copyField = 'secret-c'; state = 'success' }, @{ keyId = 'a'; copyField = 'secret-a'; state = 'success' }, @{ keyId = 'b'; copyField = 'secret-b'; state = 'success' })
        }
    }
    It 'groups numeric and named volume types with stable numbering' {
        $slots = @(Get-HuduBitLockerKeySlots -KeyMetadata $metadata)
        $slots[0].IdLabel | Should -Be 'BitLocker OS Drive 1 Key ID'
        $slots[1].PasswordLabel | Should -Be 'BitLocker Fixed Data Drive 1 Recovery Key'
        $slots[2].IdLabel | Should -Be 'BitLocker OS Drive 2 Key ID'
        @(Get-HuduBitLockerKeySlots -KeyMetadata @(@{ id = 'd'; volumeType = 3 }))[0].IdLabel | Should -Be 'BitLocker Removable Data Drive 1 Key ID'
        @(Get-HuduBitLockerKeySlots -KeyMetadata @(@{ id = 'e' }))[0].IdLabel | Should -Be 'BitLocker Unknown Drive 1 Key ID'
    }
    It 'pairs secrets with the correct IDs and clears legacy values after retrieval' {
        $fields = Get-HuduBitLockerSyncFields -KeyMetadata $metadata -ExistingFields @(@{label='BitLocker Recovery Keys';value='old'})
        $fields.bitlocker_os_drive_1_recovery_key | Should -Be 'secret-a'
        $fields.bitlocker_os_drive_2_recovery_key | Should -Be 'secret-c'
        $fields.bitlocker_fixed_data_drive_1_key_id | Should -Be 'b'
        $fields.bitlocker_fixed_data_drive_1_recovery_key | Should -Be 'secret-b'
        $fields.bitlocker_recovery_keys | Should -Be ''
    }
    It 'rejects partial retrieval without returning any field updates' {
        Mock Get-CIPPBitLockerKey { @{ keyId = 'a'; copyField = 'secret-a'; state = 'success' } }
        { Get-HuduBitLockerSyncFields -KeyMetadata $metadata } | Should -Throw '*did not match*'
    }
    It 'clears obsolete slots when metadata confirms no keys remain without revealing keys' {
        $fields = Get-HuduBitLockerSyncFields -KeyMetadata @() -ExistingFields @(@{label='BitLocker OS Drive 2 Recovery Key';value='old'})
        $fields.bitlocker_os_drive_2_recovery_key | Should -Be ''
        Should -Invoke Get-CIPPBitLockerKey -Times 0 -Exactly
    }
}
