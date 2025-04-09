BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotAlias tests' {
    It 'sleep alias' {
        $ls = Get-Alias sleep
        $ls.Description | Should -Be 'DotAlias for Start-Sleep'
    }
}

Describe 'Naughty aliases that require functions to lazy load'  {
    It 'rmdir' {
        (Get-Command rmdir).Source | Should -Be 'DotAlias'
    }

    It 'diff' {
        (Get-Command diff).Source | Should -Be 'DotAlias'
    }
}
