BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotContainer tests' {
    It 'Function asdf works' {
        asdf | Should -Be -Not $null
    }
}
