BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotContainer tests' -Skip:(-not [string]::IsNullOrEmpty($env:CI)) {
    It 'Function Get-ContainerRunner works' {
        Get-ContainerRunner | Should -Be -Not $null
    }
}
