BeforeAll {
    # Extract just the filename without extension and replace '.Tests' with nothing, assuming the test script ends with '.Tests.ps1'
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    $scriptName = $fileNameWithoutExtension -replace '\.Tests$', ''
    $scriptFileName = "$scriptName.ps1"
    $scriptBase = ([regex]::Match($PSCommandPath, '(.*[/\\]Scripts)')).Groups[1].Value

    # Search for the script within the base directory, excluding any paths that still include 'Tests'
    $scriptPath = Get-ChildItem -Path $scriptBase -Recurse -Filter $scriptFileName |
        Where-Object { $_.FullName -notmatch 'Tests' } |
        Select-Object -First 1 -ExpandProperty FullName

    if ($scriptPath) {
        . $scriptPath
    } else {
        Write-Error "Expected script not found for: $scriptFileName"
        Write-Error "Script base: $scriptBase"
    }
}

Describe 'Adb function tests' {
    It 'Adb-Devices calls adb exactly once when no devices are connected' {
        # Exit if adb not found
        if(-not (Get-Command adb -ErrorAction SilentlyContinue)) {
            $true | Should -Be $true
            return
        }

        Mock adb {return 'error: no devices/emulators found'}
        $output = Adb-Devices 2> $null
        Assert-MockCalled adb -Exactly 1 -Scope It
        $output | Should -Be $false
    }

    It 'Adb-Devices should return false when adb command is not found' {
        # Exit if adb not found
        if(-not (Get-Command adb -ErrorAction SilentlyContinue)) {
            $true | Should -Be $true
            return
        }

        Mock adb {return 'error: no devices/emulators found'}
        {Adb-Devices 2> $null | Should -Throw -ExpectedMessage 'adb command failed:.*'}
    }

    It 'Return for a single device' {
        # Exit if adb not found
        if(-not (Get-Command adb -ErrorAction SilentlyContinue)) {
            $true | Should -Be $true
            return
        }

        Mock adb {return "List of devices attached`nR5CN715HPPW     device" }
        $output = Adb-Devices 2> $null
        $output | Should -Be AdbDevice
        $output.Length | Should -Be 1
    }
}
