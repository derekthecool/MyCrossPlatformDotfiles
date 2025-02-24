BeforeAll {
    # Import the containing module
    Import-Module $PSScriptRoot/*.psd1
}

Describe 'DotPSMDTemplater tests' {
    It 'Function Get-DotPSMDTemplate works' {
        Get-DotPSMDTemplate | Should -Be -Not $null
    }
}
