BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotContainer tests' -Skip:(-not(Test-Path Env:CI)) {
    It 'Function Get-ContainerRunner works' {
        Get-ContainerRunner | Should -Be -Not $null
    }
}
