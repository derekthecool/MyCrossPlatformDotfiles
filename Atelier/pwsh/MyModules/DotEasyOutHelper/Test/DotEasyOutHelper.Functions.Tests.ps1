BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force

    # Create test directory structure
    $TestDir = Join-Path $TestDrive 'EasyOutTest'
    $null = New-Item -ItemType Directory $TestDir -Force

    # Create test object
    $TestObject = [PSCustomObject]@{
        PSTypeName  = 'Test.CustomType'
        Name        = 'Test Name'
        Value       = 42
        Description = 'Test Description'
    }
}

AfterAll {
    # Cleanup test directory
    if (Test-Path (Join-Path $TestDrive 'EasyOutTest'))
    {
        Remove-Item (Join-Path $TestDrive 'EasyOutTest') -Recurse -Force
    }
}

Describe 'Use-EasyOut Function Tests' {
    BeforeEach {
        # Change to test directory for each test
        Push-Location $TestDir
    }

    AfterEach {
        # Return to original directory
        Pop-Location
    }

    It 'Has the correct alias' {
        (Get-Command easy).Definition | Should -Be 'Use-EasyOut'
    }

    It 'Has required parameters' {
        $params = (Get-Command Use-EasyOut).Parameters

        $params.ContainsKey('InputObject') | Should -Be $true
        $params.ContainsKey('Path') | Should -Be $true
        $params.ContainsKey('Interactive') | Should -Be $true
        $params.ContainsKey('TypePrefix') | Should -Be $true
        $params.ContainsKey('ModuleName') | Should -Be $true
    }

    It 'Path parameter should not be mandatory' {
        $param = (Get-Command Use-EasyOut).Parameters['Path']
        $param.Attributes.Mandatory | Should -Be $false
    }

    It 'Creates EZOut build file if it does not exist' -Skip {
        # SKIPPED: The test body invoked `& $TestDir` where $TestDir is a
        # directory path, which always throws "not recognized as a cmdlet".
        # The original comment acknowledged this needed interactive mocking
        # to actually exercise the file-creation path. Rewrite required to
        # drive Use-EasyOut end-to-end with proper Menu/type selection mocks.
        $ezoutFile = Join-Path $TestDir 'EasyOutTest.EzFormat.ps1'

        # Ensure file doesn't exist
        if (Test-Path $ezoutFile)
        {
            Remove-Item $ezoutFile -Force
        }

        # Mock Menu to return test values
        Mock Menu {
            return @('Test.CustomType')
        }

        # This would normally prompt, but we're testing file creation
        { & $TestDir } | Should -Not -Throw

        # File should have been created
        # (Note: This test would need actual interactive mocking to work fully)
    }

    It 'Creates Formatting directory when using default path' {
        # Mock Menu to avoid interactive prompts
        Mock Menu {
            if ($Args[0] -match 'TypeNames')
            {
                return 'Test.CustomType'
            } else
            {
                return @([PSCustomObject]@{ Name = 'Name' })
            }
        }

        # Set current location to test directory
        Push-Location $TestDir

        try
        {
            # Run function with default path (should create Formatting directory)
            $result = Use-EasyOut -InputObject $TestObject -Path './Formatting/Test_CustomType.format.ps1'

            # Check that Formatting directory was created
            $formattingDir = Join-Path $TestDir 'Formatting'
            Test-Path $formattingDir | Should -Be $true
        } finally
        {
            Pop-Location
        }
    }

    It 'Uses custom path when specified' {
        $customPath = './CustomLocation/custom.format.ps1'

        # Mock Menu
        Mock Menu {
            if ($Args[0] -match 'TypeNames')
            {
                return 'Test.CustomType'
            } else
            {
                return @([PSCustomObject]@{ Name = 'Name' })
            }
        }

        Push-Location $TestDir

        try
        {
            $result = Use-EasyOut -InputObject $TestObject -Path $customPath

            # Should use the custom path
            $result | Should -Be $customPath

            # Check that custom directory was created
            $customDir = Join-Path $TestDir 'CustomLocation'
            Test-Path $customDir | Should -Be $true
        } finally
        {
            Pop-Location
        }
    }

    It 'Generates correct EZOut format syntax' {
        # Mock Menu
        Mock Menu {
            if ($Args[0] -match 'TypeNames')
            {
                return 'Test.CustomType'
            } else
            {
                return @(
                    [PSCustomObject]@{ Name = 'Name' }
                    [PSCustomObject]@{ Name = 'Value' }
                )
            }
        }

        Push-Location $TestDir

        try
        {
            $testPath = './Formatting/Test_CustomType.format.ps1'
            $result = Use-EasyOut -InputObject $TestObject -Path $testPath

            # Check that file was created
            Test-Path $testPath | Should -Be $true

            # Check file content contains expected EZOut syntax
            $content = Get-Content $testPath -Raw
            $content | Should -Match 'Write-FormatView'
            $content | Should -Match "TypeName = 'Test\.CustomType'"
            $content | Should -Match "'Name'"
            $content | Should -Match "'Value'"
        } finally
        {
            Pop-Location
        }
    }

    It 'Handles complex type names in file paths' {
        # Test that special characters in type names are handled properly
        $complexType = 'Namespace.With.Dots-And_Dashes.Type'

        # Mock Menu
        Mock Menu {
            if ($Args[0] -match 'TypeNames')
            {
                return $complexType
            } else
            {
                return @([PSCustomObject]@{ Name = 'Name' })
            }
        }

        Push-Location $TestDir

        try
        {
            $result = Use-EasyOut -InputObject $TestObject -Path './Formatting/ComplexType.format.ps1'

            # Should successfully create file without special characters causing issues
            Test-Path './Formatting/ComplexType.format.ps1' | Should -Be $true
        } finally
        {
            Pop-Location
        }
    }
}

Describe 'Use-EasyOut Interactive Mode Tests' {
    BeforeEach {
        Push-Location $TestDir
    }

    AfterEach {
        Pop-Location
    }

    It 'Returns input object in interactive mode' {
        # Mock Menu and Invoke-Expression
        Mock Menu {
            if ($Args[0] -match 'TypeNames')
            {
                return 'Test.CustomType'
            } else
            {
                return @([PSCustomObject]@{ Name = 'Name' })
            }
        }
        Mock Invoke-Expression

        $result = Use-EasyOut -InputObject $TestObject -Interactive

        # Should return the input object in interactive mode
        $result | Should -Be $TestObject
    }
}
