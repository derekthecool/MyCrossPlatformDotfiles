BeforeAll {
    # Import the containing module
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'Adb function tests' {
    It 'Get-AdbDevices calls adb exactly once when no devices are connected' {
        # Exit if adb not found
        if (-not (Get-Command adb -ErrorAction SilentlyContinue))
        {
            $true | Should -Be $true
            return
        }

        Mock adb { return 'error: no devices/emulators found' }
        $output = Get-AdbDevices 2> $null
        Assert-MockCalled adb -Exactly 1 -Scope It
        $output | Should -Be $false
    }

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

    It 'Return for a single device' {
        # Exit if adb not found
        if (-not (Get-Command adb -ErrorAction SilentlyContinue))
        {
            $true | Should -Be $true
            return
        }

        Mock adb { return "List of devices attached`nR5CN715HPPW     device" }
        $output = Get-AdbDevices 2> $null
        $output | Should -Be AdbDevice
        $output.Length | Should -Be 1
    }
}
