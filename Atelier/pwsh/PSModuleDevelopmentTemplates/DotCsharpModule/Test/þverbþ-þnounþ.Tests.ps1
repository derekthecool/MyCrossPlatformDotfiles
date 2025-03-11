BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'þnameþ tests' {
    It 'Function þverbþ-þnounþ works' {
        þverbþ-þnounþ 23 | Should -Be -Not $null
    }
}
