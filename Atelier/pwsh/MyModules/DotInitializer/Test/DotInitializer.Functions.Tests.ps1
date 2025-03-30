BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force -Verbose
    $VerbosePreference = 'Continue'
    $DebugPreference = 'Continue'
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
                70
            }
            default
            {
                1
            }
        }
        $packages | Should -BeGreaterOrEqual
    }

    It 'Function Install-DotPackages works (this may be too slow to test)' -Skip:($CI -eq $false) {
        Install-DotPackages
        # {Get-DotPackages} | Should -Not -Throw
    }

    It 'Function Update-DotPackages' {
        {Update-DotPackages} | Should -Throw
    }

    # It 'Get-Package Check' {
    #     Get-Package
    # }
}
