BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'Dot tests' {
    It 'Function dot works' {
        Get-Command dot | Should -Be -Not $null
    }

    It 'Dot should load very fast' {
        $time = Measure-Command { Import-Module $PSScriptRoot/../*.psd1 -Force }
        $time.TotalMilliseconds | Should -BeLessThan 50
    }

    It 'Can call dot' {
        { dot } | Should -Not -Throw
    }

    It 'Can call dot with an argument' {
        { dot @('status') 2> $null } | Should -Not -Throw
    }
}
