BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotConventionalCommits tests' {
    It 'Function Get-ConventionalCommitValues works' {
        Get-ConventionalCommitValues | Should -Be -Not $null
    }

    It 'Function Get-ConventionalCommitValues should be an array' {
        (Get-ConventionalCommitValues).Length | Should -BeGreaterOrEqual 11
    }

    It 'Module should load super FAST!' {
        $Time = Measure-Command { Import-Module $PSScriptRoot/../*.psd1 -Force }
        $Time.TotalMilliseconds | Should -BeLessOrEqual 50
    }
}
