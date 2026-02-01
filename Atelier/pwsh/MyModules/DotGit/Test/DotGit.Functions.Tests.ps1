BeforeAll {
    $module = Import-Module $PSScriptRoot/../*.psd1 -Force -PassThru
}

Describe 'DotGit tests' {
    It 'Function Switch-GitWorktree works' {
        $module.ExportedFunctions['Get-GitWorktree'] | Should -Be -Not $null
    }
}
