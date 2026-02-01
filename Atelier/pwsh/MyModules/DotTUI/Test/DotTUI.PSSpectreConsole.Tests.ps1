BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotTUI Terminal.GUI v1 tests' {
    It 'Function Show-TerminalGuiV1Example exists' {
        Get-Command Show-TerminalGuiV1Example | Should -Be -Not $null
    }
}
