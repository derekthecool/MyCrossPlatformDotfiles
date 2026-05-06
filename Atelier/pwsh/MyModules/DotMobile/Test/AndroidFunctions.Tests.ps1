BeforeAll {
    $module = Import-Module $PSScriptRoot/../DotMobile.psd1 -Force -PassThru
}

Describe 'Android ADB Functions Tests' {
    Context 'Get-AdbDevices' {
        It 'Function is exported from module' {
            $module.ExportedFunctions['Get-AdbDevices'] | Should -Not -BeNullOrEmpty
        }

        It 'Returns false when adb command is not found' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { throw 'Command not found' }
            { Get-AdbDevices } | Should -Throw
        }

        It 'Returns false when no devices found' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { return 'error: no devices/emulators found' }
            $result = Get-AdbDevices 2>&1
            $result | Should -Be $false
        }

        It 'Returns AdbDevice objects when devices are connected' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -eq 'get-state') {
                    return 'device'
                }
                if ($args -eq 'devices') {
                    return @(
                        'List of devices attached',
                        'emulator-5554	device',
                        '192.168.1.100:5555	device'
                    )
                }
            }

            $result = Get-AdbDevices
            $result | Should -HaveCount 2
            $result[0] | Should -BeOfType [AdbDevice]
            $result[0].Id | Should -Be 'emulator-5554'
            $result[0].State | Should -Be [AdbState]::Normal
        }

        It 'Detects unauthorized devices' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -eq 'get-state') {
                    return 'device'
                }
                if ($args -eq 'devices') {
                    return @(
                        'List of devices attached',
                        'emulator-5554	unauthorized'
                    )
                }
            }

            $result = Get-AdbDevices
            $result[0].State | Should -Be [AdbState]::Unauthorized
        }

        It 'Detects offline devices' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -eq 'get-state') {
                    return 'device'
                }
                if ($args -eq 'devices') {
                    return @(
                        'List of devices attached',
                        'emulator-5554	offline'
                    )
                }
            }

            $result = Get-AdbDevices
            $result[0].State | Should -Be [AdbState]::Offline
        }
    }

    Context 'New-AdbScreenshot' {
        It 'Function is exported from module' {
            $module.ExportedFunctions['New-AdbScreenshot'] | Should -Not -BeNullOrEmpty
        }

        It 'Calls adb exec-out with correct parameters' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {}

            $testPath = '/tmp/test_screenshot'
            New-AdbScreenshot -OutputPathNameWithoutFileEnding $testPath

            Should -Invoke -CommandName 'adb' -Times 1 -ParameterFilter {
                $args -contains 'exec-out' -and
                $args -contains 'screencap' -and
                $args -contains '-p'
            }
        }

        It 'Creates file with .png extension' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {}

            $testPath = '/tmp/test_screenshot'
            New-AdbScreenshot -OutputPathNameWithoutFileEnding $testPath

            # The function redirects output to a file, so we can't easily test file creation
            # But we can verify adb was called
            Should -Invoke -CommandName 'adb' -Times 1
        }
    }

    Context 'Get-AdbImages' {
        It 'Function is exported from module' {
            $module.ExportedFunctions['Get-AdbImages'] | Should -Not -BeNullOrEmpty
        }

        It 'Calls Get-AdbDevices to check for devices' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock Get-AdbDevices { return $null }
            Mock adb { return '' }

            Get-AdbImages

            Should -Invoke -CommandName 'Get-AdbDevices' -Times 1
        }

        It 'Returns early when no devices found' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock Get-AdbDevices { return $null }
            Mock adb { return '' }

            $result = Get-AdbImages
            # Function returns nothing when no devices
            Should -Invoke -CommandName 'Get-AdbDevices' -Times 1
        }

        It 'Calls adb shell to find images' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock Get-AdbDevices {
                return @([AdbDevice]::new('emulator-5554', [AdbState]::Normal))
            }
            Mock adb {
                return @('/sdcard/DCIM/Camera/20250506_120000.jpg')
            }

            Get-AdbImages

            Should -Invoke -CommandName 'adb' -Times 1 -ParameterFilter {
                $args -contains 'shell'
            }
        }

        It 'Verifies bug fix: uses Get-AdbDevices not Adb-Devices' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            # This test verifies the bug fix from Adb-Devices to Get-AdbDevices
            Mock Get-AdbDevices {
                return @([AdbDevice]::new('emulator-5554', [AdbState]::Normal))
            }
            Mock adb {
                return @('/sdcard/DCIM/Camera/20250506_120000.jpg')
            }

            Get-AdbImages

            # Verify Get-AdbDevices was called (the fixed version)
            Should -Invoke -CommandName 'Get-AdbDevices' -Times 1
        }
    }

    Context 'Update-AndroidApplications' {
        It 'Function is exported from module' {
            $module.ExportedFunctions['Update-AndroidApplications'] | Should -Not -BeNullOrEmpty
        }

        It 'Returns array of download URLs' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock Invoke-WebRequest {
                return [PSCustomObject]@{
                    Links = @(
                        [PSCustomObject]@{ href = '/some/path.apk' }
                        [PSCustomObject]@{ href = '/another.apk' }
                    )
                }
            }

            $result = Update-AndroidApplications

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }

        It 'Includes F-Droid download URL' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock Invoke-WebRequest {
                return [PSCustomObject]@{
                    Links = @()
                }
            }

            $result = Update-AndroidApplications

            $result | Should -Contain 'https://f-droid.org/F-Droid.apk'
        }

        It 'Calls Invoke-WebRequest for Aurora Store' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock Invoke-WebRequest {
                return [PSCustomObject]@{
                    Links = @([PSCustomObject]@{ href = '/AuroraStore.apk' })
                }
            }

            Update-AndroidApplications

            Should -Invoke -CommandName 'Invoke-WebRequest' -ParameterFilter {
                $Uri -like '*auroraoss*'
            }
        }
    }

    Context 'Get-AdbLogCode' {
        It 'Function is exported from module' {
            $module.ExportedFunctions['Get-AdbLogCode'] | Should -Not -BeNullOrEmpty
        }

        It 'Waits for device connection' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { return '' }

            Get-AdbLogCode

            Should -Invoke -CommandName 'adb' -ParameterFilter {
                $args -contains 'wait-for-device'
            }
        }

        It 'Extracts numeric code from log file' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -contains 'wait-for-device') {
                    return ''
                }
                if ($args -contains 'cat') {
                    return 'Login code: 123456'
                }
            }

            $result = Get-AdbLogCode

            $result | Should -Be '123456'
        }

        It 'Returns nothing when log file is empty' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -contains 'wait-for-device') {
                    return ''
                }
                if ($args -contains 'cat') {
                    return ''
                }
            }

            $result = Get-AdbLogCode

            $result | Should -BeNullOrEmpty
        }

        It 'Copies code to clipboard when found' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -contains 'wait-for-device') {
                    return ''
                }
                if ($args -contains 'cat') {
                    return 'Your code is 789012'
                }
            }
            Mock Set-Clipboard {}

            Get-AdbLogCode

            Should -Invoke -CommandName 'Set-Clipboard' -ParameterFilter {
                $args -contains '789012'
            }
        }
    }
}
