BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotArt tests' -Skip:(-not(Test-Path Env:CI)) {
    It 'Function Show-ChristmasTree works' {
        Get-Command Show-ChristmasTree | Should -Be -Not $null
    }
}
