BeforeAll {
    Import-Module $PSScriptRoot/../../Dots/Dots.psd1 -Force
}

Describe 'Mason tools in path' {
    It 'Should add mason bin path to path environment variable' {
        Add-MasonToolsToPath
        { $env:Path -match 'mason' } | Should -Be $true
    }
}
