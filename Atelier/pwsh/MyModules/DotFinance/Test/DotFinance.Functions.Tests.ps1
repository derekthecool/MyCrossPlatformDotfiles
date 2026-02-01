BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotFinance tests' {
    It 'Function Get-Tithing works' {
        Get-Command Get-Tithing | Should -Be -Not $null
    }
}
