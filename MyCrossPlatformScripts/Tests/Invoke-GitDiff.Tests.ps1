BeforeAll {
    . $PSScriptRoot/../PowershellTools/Invoke-GitDiff.ps1
}

Describe 'Using git as a diff tool tests' {
    It 'Can run function' {
        { Invoke-GitDiff 2> $null } | Should -Not -Throw
    }

    It 'Calls git with any arguments' {
        Mock git {}
        Invoke-GitDiff 2> $null
        Assert-MockCalled git -Exactly 1 -Scope It
    }

}
