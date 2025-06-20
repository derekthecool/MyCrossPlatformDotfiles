BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

# Skip these tests if the configuration directory is not found
Describe 'DotPlover tests' -Skip:$(-not (Test-Path (Get-PloverConfigurationDirectory))) {
    It 'Get-PloverConfigurationDirectory works' {
        Get-PloverConfigurationDirectory | Should -Be -Not $null
    }
}
