BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotTUI tests' {
    It 'Function Show-DotTUI works' {
        Get-Command Show-DotTUI | Should -Be -Not $null
    }
}
