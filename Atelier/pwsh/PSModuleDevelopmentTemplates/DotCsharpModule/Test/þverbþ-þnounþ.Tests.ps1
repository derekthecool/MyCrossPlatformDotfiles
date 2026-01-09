BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'þnameþ tests' {
    It 'Function þverbþ-þnounþ exists' {
        Get-Command þverbþ-þnounþ | Should -Be -Not $null
    }
}
