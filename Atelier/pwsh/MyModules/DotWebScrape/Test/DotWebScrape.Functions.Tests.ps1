BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotWebScrape tests' {
    It 'Function Get-Site works' {
        Get-Site -Url 'https://www.lua.org/manual/5.4/manual.html' | Should -Be -Not $null
    }
}
