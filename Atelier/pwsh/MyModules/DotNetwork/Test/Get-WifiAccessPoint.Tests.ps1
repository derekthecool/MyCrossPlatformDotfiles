BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotNetwork tests' {
    Context 'Wifi scanning' {
        It 'Function Get-WifiAccessPoint exists' {
            Get-Command Get-WifiAccessPoint | Should -Be -Not $null
        }
    }
}
