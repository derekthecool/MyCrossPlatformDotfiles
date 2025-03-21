BeforeAll {
    $DebugPreference = 'Continue'
    Import-Module $PSScriptRoot/../*.psd1 -Force -Verbose -PassThru -Debug
}

Describe 'DotYT tests' {
    It 'Function Find-YTData is found' {
        Get-Command Find-YTData |  Should -Be -Not $null
    }

    It 'Function Get-YTData works' {
        $results = Find-YTData -SearchQuery 'powershell'
        $results | Should -Be -Not $null
        ($results).Count | Should -BeGreaterOrEqual 10
    }
}
