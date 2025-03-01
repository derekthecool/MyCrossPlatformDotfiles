BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPSMDTemplater tests' {
    It 'Function Get-DotPSMDTemplate works' {
        Get-DotPSMDTemplate | Should -Be -Not $null
    }
}
