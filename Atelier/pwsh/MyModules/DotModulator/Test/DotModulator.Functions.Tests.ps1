BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotModulator tests' {
    It 'Function Format-PowershellScriptFile exists' {
        Get-Command Format-PowershellScriptFile | Should -Be -Not $null
    }
}


