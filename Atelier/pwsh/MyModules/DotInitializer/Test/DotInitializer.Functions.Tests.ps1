BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force -Verbose
}

Describe 'DotInitializer tests' {
    $CI = -not [string]::IsNullOrEmpty($env:CI)

    It 'Function Get-DotPackages works' {
        $packages = Get-DotPackageList
        $packages | Should -Be -Not $null

        switch ($null)
        {
            {$IsWindows}
            {
                76
            }
            default
            {
                8
            }
        }
        $packages | Should -BeGreaterOrEqual
    }

    It 'Function Install-DotPackages works (this may be too slow to test)' -Skip:($CI -eq $false) {
        {Install-DotPackages} | Should -Not -Throw
        {Get-DotPackages} | Should -Not -Throw
    }

    It 'Function Update-DotPackages' {
        {Update-DotPackages} | Should -Throw
    }
}
