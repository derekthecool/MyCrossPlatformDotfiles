BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotArt tests' {
    It 'Function Show-ChristmasTree works' {
        Get-Command Show-ChristmasTree | Should -Be -Not $null
    }
}
