BeforeAll {
    . $PSScriptRoot/../Invoke-DotGit.ps1
}

Describe 'dot Tests' {
    It 'Can call dot' {
        { dot -Arguments @() } | Should -Not -Throw
    }

    It 'Can call dot with an argument' {
        { dot @('status') } | Should -Not -Throw
    }

    It 'Calls git with any arguments' {
        Mock git {}
        dot 'status'
        Assert-MockCalled git -Exactly 1 -Scope It
    }

    It "Removes 'git' from the beginning of the arguments" {
        # Mock git to intercept and inspect the call
        Mock git {}

        dot 'git' 'status'
        # Assert that git was called with 'status' only
        Assert-MockCalled git -Exactly 1 -Scope It -ParameterFilter { $Args -contains 'status' -and $Args.Contains('git') -eq $false }
    }
}
