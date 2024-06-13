BeforeAll {
    . $PSScriptRoot/Flutter-Functions.ps1
}

# Check if the dotnet command is available
$dotnetCommand = Get-Command flutter -ErrorAction SilentlyContinue

# Determine if the tests should be skipped
$skipTests = -not $dotnetCommand

Describe 'Test flutter help global options' -Skip:$skipTests {
    It 'Should not be null' {
        Get-FlutterGlobalOptions | Should -Not -Be $null
    }

    It 'Should not be an empty string' {
        [string]::IsNullOrEmpty($(Get-FlutterGlobalOptions)) | Should -Be $false
    }

    It 'Should be a custom object' {
        Get-FlutterGlobalOptions | Should -BeOfType [System.Management.Automation.PSCustomObject]
    }

    It 'Should return 7 global options' {
        Get-FlutterGlobalOptions | Should -HaveCount 7
    }
}

Describe 'Testing Get-FlutterCommandsAndNonGlobalOptions' -Skip:$skipTests {
    It 'Get-FlutterCommandsAndNonGlobalOptions with input [<InputCommand>] should contain this many <OptionsOrCommands> options or commands' -TestCases @(
        @{
            InputCommand = 'flutter'
            OptionsOrCommands = 33
        }
        @{
            InputCommand = 'flutter run'
            OptionsOrCommands = 41
        }
    ){
        Get-FlutterCommandsAndNonGlobalOptions -FlutterCommand $InputCommand | Should -HaveCount $OptionsOrCommands
    }
}
