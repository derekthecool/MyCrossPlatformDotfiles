BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotHomeServer tests' -Skip:(-not(Test-Path Env:CI)) {
    It 'Function Sync-Dev exists' {
        Get-Command Sync-Dev | Should -Be -Not $null
    }

    It 'Excludes are defined' {
        InModuleScope DotHomeServer { $DevSyncExcludes } | Should -Not -BeNullOrEmpty
    }
}
