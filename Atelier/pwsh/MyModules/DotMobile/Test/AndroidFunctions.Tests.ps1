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
                if ($args -eq 'get-state')
                {
                    return 'device'
                }
                if ($args -eq 'devices')
                {
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
                if ($args -eq 'get-state')
                {
                    return 'device'
                }
                if ($args -eq 'devices')
                {
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
                if ($args -eq 'get-state')
                {
                    return 'device'
                }
                if ($args -eq 'devices')
                {
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

        It 'Prompts via Read-Host when -Name not provided' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }
            # Loop mode: first prompt returns a name, second returns blank to exit.
            $script:promptCount = 0
            Mock Read-Host {
                $script:promptCount++
                if ($script:promptCount -eq 1) { 'prompted-name' } else { '' }
            }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Path $tempDir
                Should -Invoke -CommandName 'Read-Host' -Times 2
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Loops until blank name is entered, capturing each' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }
            $script:promptCount = 0
            Mock Read-Host {
                $script:promptCount++
                switch ($script:promptCount)
                {
                    1 { 'shot-one' }
                    2 { 'shot-two' }
                    default { '' }
                }
            }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                $result = New-AdbScreenshot -Path $tempDir

                Should -Invoke -CommandName 'adb' -Times 2 -ParameterFilter { $args -contains 'pull' }
                $result | Should -HaveCount 2
                $result[0].Name | Should -Be 'shot-one.png'
                $result[1].Name | Should -Be 'shot-two.png'
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses -Name directly when provided (no Read-Host)' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }
            Mock Read-Host { 'should-not-be-called' }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name direct-name -Path $tempDir
                Should -Invoke -CommandName 'Read-Host' -Times 0
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Calls adb shell screencap with device-side path (binary-safe pattern)' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name shot -Path $tempDir

                Should -Invoke -CommandName 'adb' -Times 1 -ParameterFilter {
                    $args -contains 'shell' -and
                    $args -contains 'screencap' -and
                    $args -contains '-p' -and
                    ($args -join ' ') -match '/sdcard/DotMobile_capture_'
                }
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Calls adb pull to retrieve the captured PNG' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name shot -Path $tempDir

                Should -Invoke -CommandName 'adb' -Times 1 -ParameterFilter {
                    $args -contains 'pull'
                }
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Calls adb shell rm -f for cleanup' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name shot -Path $tempDir

                Should -Invoke -CommandName 'adb' -Times 1 -ParameterFilter {
                    $args -contains 'rm' -and $args -contains '-f'
                }
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Passes -s <serial> when Serial provided' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name shot -Serial R5CN12345 -Path $tempDir

                Should -Invoke -CommandName 'adb' -Times 1 -ParameterFilter {
                    ($args -join ' ') -match '-s R5CN12345'
                }
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Invokes Add-DeviceFrame when -Frame is set' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }
            Mock Add-DeviceFrame { [PSCustomObject]@{ FullName = 'mocked-framed.png' } } -ModuleName DotMobile

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name shot -Path $tempDir -Frame

                Should -Invoke -CommandName 'Add-DeviceFrame' -Times 1 -ModuleName DotMobile
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Does NOT invoke Add-DeviceFrame when -Frame is omitted' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }
            Mock Add-DeviceFrame { } -ModuleName DotMobile

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name shot -Path $tempDir

                Should -Invoke -CommandName 'Add-DeviceFrame' -Times 0 -ModuleName DotMobile
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Removes existing PNGs in raw and sibling framed dirs when -RemoveExisting is set' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }

            $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            $rawDir = Join-Path $tempRoot 'raw'
            $framedDir = Join-Path $tempRoot 'framed'
            try
            {
                New-Item -ItemType Directory -Path $rawDir -Force | Out-Null
                New-Item -ItemType Directory -Path $framedDir -Force | Out-Null
                'old1', 'old2' | ForEach-Object {
                    [IO.File]::WriteAllBytes((Join-Path $rawDir   "$_.png"), [byte[]](0x89, 0x50))
                    [IO.File]::WriteAllBytes((Join-Path $framedDir "$_.png"), [byte[]](0x89, 0x50))
                }

                # -WhatIf: nothing actually removed, mock adb still called for the test
                { New-AdbScreenshot -Name shot -Path $rawDir -RemoveExisting -WhatIf } | Should -Not -Throw
                (Get-ChildItem $rawDir -Filter '*.png').Count | Should -Be 2
                (Get-ChildItem $framedDir -Filter '*.png').Count | Should -Be 2

                # Real run: existing PNGs gone, new one captured.
                New-AdbScreenshot -Name shot -Path $rawDir -RemoveExisting
                (Get-ChildItem $rawDir -Filter '*.png').Count | Should -Be 1
            }
            finally
            {
                Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Respects -WhatIf: skips adb capture entirely' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb { $global:LASTEXITCODE = 0 }

            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-AdbScreenshot -Name shot -Path $tempDir -WhatIf

                # Under -WhatIf, the function returns before any adb call.
                Should -Invoke -CommandName 'adb' -Times 0
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Add-DeviceFrame' {
        It 'Function is exported from module' {
            $module.ExportedFunctions['Add-DeviceFrame'] | Should -Not -BeNullOrEmpty
        }

        It 'Throws when input screenshot missing' {
            $tempDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            try
            {
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                { Add-DeviceFrame -Name missing -Path $tempDir -DestinationPath $tempDir } | Should -Throw
            }
            finally
            {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        BeforeEach {
            # Mocks need -ModuleName DotMobile because Add-DeviceFrame runs in the
            # module's session state, not the test scope. Without -ModuleName, real
            # magick gets invoked.
            Mock magick { $global:LASTEXITCODE = 0 } -ModuleName DotMobile
            Mock Get-Item { [PSCustomObject]@{ FullName = 'mocked-output.png' } } -ModuleName DotMobile

            $script:testRawDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-test-$([guid]::NewGuid())"
            New-Item -ItemType Directory -Path $script:testRawDir -Force | Out-Null
            $inputPng = Join-Path $script:testRawDir 'shot.png'
            [IO.File]::WriteAllBytes($inputPng, [byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))
        }

        AfterEach {
            Remove-Item $script:testRawDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Calls magick 4 times for the framing pipeline' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            Add-DeviceFrame -Name shot -Path $script:testRawDir -DestinationPath (Join-Path $script:testRawDir 'framed')
            Should -Invoke -CommandName 'magick' -Times 4 -ModuleName DotMobile
        }

        It 'Uses -crop on the mask in step 1 with bundled mask path' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            Add-DeviceFrame -Name shot -Path $script:testRawDir -DestinationPath (Join-Path $script:testRawDir 'framed')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains '-crop' -and
                ($args -join ' ') -match 'Pixel9ProXL[\\/]mask\.png'
            }
        }

        It 'Uses -compose copyopacity in step 3' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            Add-DeviceFrame -Name shot -Path $script:testRawDir -DestinationPath (Join-Path $script:testRawDir 'framed')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains 'copyopacity'
            }
        }

        It 'Composites onto bundled frame in step 4' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            Add-DeviceFrame -Name shot -Path $script:testRawDir -DestinationPath (Join-Path $script:testRawDir 'framed')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                ($args -join ' ') -match 'Pixel9ProXL[\\/]frame\.png' -and
                $args -contains 'northwest'
            }
        }

        It 'Accepts pipeline input and derives framed dir as sibling of raw dir' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            # $script:testRawDir is shot.png's location; pipeline mode should write to
            # <parent>/framed/shot.png. Move the raw file under a 'raw' subdir to make
            # the sibling relationship explicit and verify the derivation.
            $tempRoot = Split-Path $script:testRawDir -Parent
            $rawSubDir = Join-Path $tempRoot 'raw'
            New-Item -ItemType Directory -Path $rawSubDir -Force | Out-Null
            Move-Item (Join-Path $script:testRawDir 'shot.png') (Join-Path $rawSubDir 'shot.png') -Force

            $file = Get-Item (Join-Path $rawSubDir 'shot.png')
            $file | Add-DeviceFrame

            $sep = [IO.Path]::DirectorySeparatorChar
            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                ($args -join ' ') -match ('framed' + [regex]::Escape($sep) + 'shot\.png')
            }
        }

        It 'Respects -WhatIf: skips all magick calls' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            Add-DeviceFrame -Name shot -Path $script:testRawDir -DestinationPath (Join-Path $script:testRawDir 'framed') -WhatIf

            Should -Invoke -CommandName 'magick' -Times 0 -ModuleName DotMobile
        }
    }

    Context 'New-FeatureGraphic' {
        BeforeEach {
            Mock magick { $global:LASTEXITCODE = 0 } -ModuleName DotMobile
            Mock Get-Item { [PSCustomObject]@{ FullName = 'mocked-feature.png' } } -ModuleName DotMobile

            $script:fgTestDir = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-fg-$([guid]::NewGuid())"
            New-Item -ItemType Directory -Path $script:fgTestDir -Force | Out-Null
            $script:fgShotPath = Join-Path $script:fgTestDir 'shot.png'
            [IO.File]::WriteAllBytes($script:fgShotPath, [byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))
        }

        AfterEach {
            Remove-Item $script:fgTestDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Function is exported from module' {
            $module.ExportedFunctions['New-FeatureGraphic'] | Should -Not -BeNullOrEmpty
        }

        It 'Throws when screenshot missing' {
            { New-FeatureGraphic -ScreenshotPath (Join-Path $script:fgTestDir 'nope.png') -Title 'T' -OutputPath (Join-Path $script:fgTestDir 'out.png') } | Should -Throw
        }

        It 'Calls magick 5 times for canvas/resize/composite/text/flatten' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'svgaze' -OutputPath (Join-Path $script:fgTestDir 'out.png')
            Should -Invoke -CommandName 'magick' -Times 5 -ModuleName DotMobile
        }

        It 'Uses gradient: primitive when -GradientColors is provided' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -GradientColors '#111111', '#222222' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                ($args -join ' ') -match 'gradient:#111111-#222222'
            }
        }

        It 'Uses xc: solid fill when -GradientColors is not provided' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -BackgroundColor '#abcdef' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                ($args -join ' ') -match 'xc:#abcdef'
            }
        }

        It 'Resizes screenshot to 256px wide in a dedicated step' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains '256x' -and -not ($args -contains 'east')
            }
        }

        It 'Composites the resized screenshot east-aligned' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains 'east' -and $args -contains '-composite'
            }
        }

        It 'Renders title at +82+180 via -annotate' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'MyApp' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains '+82+180' -and $args -contains 'MyApp'
            }
        }

        It 'Renders subtitle at +82+260 only when -Subtitle is provided' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -Subtitle 'Tagline here' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains '+82+260' -and $args -contains 'Tagline here'
            }
        }

        It 'Omits subtitle annotate when -Subtitle is not provided' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 0 -ModuleName DotMobile -ParameterFilter {
                $args -contains '+82+260'
            }
        }

        It 'Writes 24-bit PNG via png:color-type=2 in flatten step' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains 'png:color-type=2' -and $args -contains 'remove'
            }
        }

        It 'Passes -Font through to magick when provided' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -Font '/tmp/fake.ttf' -OutputPath (Join-Path $script:fgTestDir 'out.png')

            Should -Invoke -CommandName 'magick' -Times 1 -ModuleName DotMobile -ParameterFilter {
                $args -contains '-font' -and $args -contains '/tmp/fake.ttf'
            }
        }

        It 'Respects -WhatIf: skips all magick calls' -Skip:([bool](!(Get-Command magick -ErrorAction SilentlyContinue))) {
            New-FeatureGraphic -ScreenshotPath $script:fgShotPath -Title 'T' -OutputPath (Join-Path $script:fgTestDir 'out.png') -WhatIf

            Should -Invoke -CommandName 'magick' -Times 0 -ModuleName DotMobile
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
                if ($args -contains 'wait-for-device')
                {
                    return ''
                }
                if ($args -contains 'cat')
                {
                    return 'Login code: 123456'
                }
            }

            $result = Get-AdbLogCode

            $result | Should -Be '123456'
        }

        It 'Returns nothing when log file is empty' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -contains 'wait-for-device')
                {
                    return ''
                }
                if ($args -contains 'cat')
                {
                    return ''
                }
            }

            $result = Get-AdbLogCode

            $result | Should -BeNullOrEmpty
        }

        It 'Copies code to clipboard when found' -Skip:([bool](!(Get-Command adb -ErrorAction SilentlyContinue))) {
            Mock adb {
                param($args)
                if ($args -contains 'wait-for-device')
                {
                    return ''
                }
                if ($args -contains 'cat')
                {
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
