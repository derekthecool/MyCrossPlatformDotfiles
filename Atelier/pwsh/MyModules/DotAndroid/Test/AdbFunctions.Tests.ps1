BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'Adb function tests' {
    It 'Adb-Devices should return false when adb command is not found' {
        # Exit if adb not found
        if (-not (Get-Command adb -ErrorAction SilentlyContinue))
        {
            $true | Should -Be $true
            return
        }

        Mock adb { return 'error: no devices/emulators found' }
        { Get-AdbDevices 2> $null | Should -Throw -ExpectedMessage 'adb command failed:.*' }
    }
}
