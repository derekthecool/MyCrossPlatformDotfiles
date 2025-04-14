BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotAlias tests' {
    It 'sleep alias' {
        $ls = Get-Alias sleep
        $ls.Description | Should -Be 'DotAlias for Start-Sleep'
    }
}

# These tests are not working in GitHub actions for some reason
# TODO: (Derek Lomax) 4/14/2025 11:22:38 AM, Find out why they do not work
Describe 'Naughty aliases that require functions to lazy load' -Skip:((Test-Path Env:CI)) {
    It 'rmdir' {
        (Get-Command rmdir).Source | Should -Be 'DotAlias'
    }

    It 'diff' {
        (Get-Command diff).Source | Should -Be 'DotAlias'
    }
}
