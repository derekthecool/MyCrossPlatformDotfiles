BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'þnameþ tests' {
    It 'Function þFirst-Functionþ exists' {
        Get-Command þFirst-Functionþ | Should -Be -Not $null
    }
}
