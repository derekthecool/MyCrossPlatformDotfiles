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

    It 'Flutter output dirs are whitelisted ahead of the build excludes' {
        $includes = InModuleScope DotHomeServer { $DevSyncIncludes }
        $excludes = InModuleScope DotHomeServer { $DevSyncExcludes }
        $includes | Should -Contain '*/build/app/outputs/**'
        $excludes | Should -Contain '*/build/**'
    }

    It 'Get-DevSyncLocalTree keeps trees under the home directory' {
        InModuleScope DotHomeServer { Get-DevSyncLocalTree -Tree 'LSS' } |
            Should -Be (Join-Path $HOME 'LSS')
        InModuleScope DotHomeServer { Get-DevSyncLocalTree -Tree 'projects' } |
            Should -Be (Join-Path $HOME 'projects')
    }

    It 'Get-DevSyncLocalTree refuses the home directory itself' {
        { InModuleScope DotHomeServer { Get-DevSyncLocalTree -Tree '.' } } |
            Should -Throw
    }

    It 'Get-DevSyncLocalTree refuses trees that escape the home directory' {
        { InModuleScope DotHomeServer { Get-DevSyncLocalTree -Tree '../etc' } } |
            Should -Throw
    }
}
