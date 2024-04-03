BeforeAll {
    . $PSScriptRoot/../../PowershellTools/NeovimRelated/Add-MasonToolsToPath.ps1
}

Describe 'Mason tools in path' {
    It 'Should add mason bin path to path environment variable' {
        Add-MasonToolsToPath
        {$env:Path -match 'mason'} | Should -Be $true
    }
}
