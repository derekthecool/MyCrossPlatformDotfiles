BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'þnameþ tests' {
    It 'Function þFirst-Functionþ works' {
        þFirst-Functionþ | Should -Be -Not $null
    }
}
