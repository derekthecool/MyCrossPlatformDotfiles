BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotAdventOfCode tests' {
    It 'Function Get-AdventOfCodeData exists' {
        Get-Command Get-AdventOfCodeData | Should -Be -Not $null
    }
}
