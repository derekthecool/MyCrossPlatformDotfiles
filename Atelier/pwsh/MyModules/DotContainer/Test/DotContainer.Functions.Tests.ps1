BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotContainer tests' {
    It 'Function Get-ContainerRunner works' {
        Get-ContainerRunner | Should -Be -Not $null
    }
}
