BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'Yazi helper tests' {
    It 'Function y works' {
        Get-Command y | Should -Be -Not $null
    }
}
