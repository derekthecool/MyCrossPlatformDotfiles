BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotShowOff tests' {
    It 'Function Show-Object works' {
        Show-Object | Should -Be -Not $null
    }
}
