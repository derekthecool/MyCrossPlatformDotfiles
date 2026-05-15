BeforeAll {
    $module = Import-Module $PSScriptRoot/../*.psd1 -Force -PassThru
}

Describe 'DotGit tests' {
    It 'Function Switch-GitWorktree works' {
        $module.ExportedFunctions['Get-GitWorktree'] | Should -Be -Not $null
    }
}

Describe 'Get-LatestGithubRelease' {
    BeforeEach {
        # Use a well-known repository that should have releases
        $testRepo = 'opensteno/plover'
    }

    It 'Returns a PSCustomObject with expected properties' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.TypeNames[0] | Should -Be 'System.Management.Automation.PSCustomObject'
    }

    It 'Returns TagName property with version format' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.TagName | Should -Not -BeNullOrEmpty
        $result.TagName | Should -Match '^v?\d+\.\d+\.\d+'
    }

    It 'Returns Assets array with metadata' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.Assets | Should -Not -BeNullOrEmpty
        $result.Assets.Count | Should -BeGreaterThan 0

        $firstAsset = $result.Assets[0]
        $firstAsset.Name | Should -Not -BeNullOrEmpty
        $firstAsset.BrowserDownloadUrl | Should -Not -BeNullOrEmpty
        $firstAsset.BrowserDownloadUrl | Should -Match '^https://'
        $firstAsset.Size | Should -BeGreaterThan 0
    }

    It 'Maintains backward compatibility with DownloadUrls property' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.DownloadUrls | Should -Not -BeNullOrEmpty
        $result.DownloadUrls.GetType().Name | Should -Be 'Object[]'
        $result.DownloadUrls[0] | Should -Match '^https://'
    }

    It 'Returns HtmlUrl property' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.HtmlUrl | Should -Not -BeNullOrEmpty
        $result.HtmlUrl | Should -Match '^https://github\.com/'
    }

    It 'Returns PublishedAt property' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.PublishedAt | Should -Not -BeNullOrEmpty
        $result.PublishedAt | Should -BeOfType System.DateTime
    }

    It 'Validates Repo parameter format' {
        # Invalid patterns should throw during parameter validation
        { Get-LatestGithubRelease -Repo 'invalid-format' } | Should -Throw -ErrorId '*ParameterArgumentValidationError*'
        { Get-LatestGithubRelease -Repo 'singleword' } | Should -Throw -ErrorId '*ParameterArgumentValidationError*'

        # Valid pattern should be accepted by parameter validator (will get 404 from API)
        { Get-LatestGithubRelease -Repo 'this/repo-does-not-exist-12345' } | Should -Throw -ErrorId '*WebCmdletWebResponseException*'
    }
}

Describe 'Start-GitBisect' {
    It 'Function Start-GitBisect exists' {
        $module.ExportedFunctions['Start-GitBisect'] | Should -Be -Not $null
    }

    It 'Alias bisect exists' {
        $module.ExportedAliases['bisect'] | Should -Be -Not $null
    }

    It 'Good and Bad parameter aliases work' {
        # Test that parameter aliases are accepted
        { Start-GitBisect -Good 'abc123' -Bad 'def456' } | Should -Not -Throw
    }

    It 'SkipRegex and SkipScriptBlock are mutually exclusive' {
        # Should throw when both are provided
        {
            Start-GitBisect -ScriptBlock { } -SkipRegex 'error' -SkipScriptBlock { }
        } | Should -Throw
    }
}

Describe 'Start-GitBisect Integration Tests' {
    BeforeEach {
        # Create test repository in TestDrive: (auto-cleaned by Pester)
        $repoPath = 'TestDrive:/TestRepo'
        New-Item -Path $repoPath -ItemType Directory -Force | Out-Null
        Push-Location $repoPath

        # Initialize git repo
        $null = git init 2>&1
        git config user.name 'Test User'
        git config user.email 'test@example.com'
        git config advice.defaultBranchName false | Out-Null  # Suppress branch name hint

        # Create a PowerShell function that will have a bug introduced
        $functionPath = './MyFunction.ps1'

        # Commits 1-5: Working function
        1..5 | ForEach-Object {
            $commitNum = $_
            @'
function Get-Value {
    param([int]$x)
    return $x * 2
}
'@ | Set-Content $functionPath
            git add $functionPath
            $null = git commit -m "Commit $commitNum`: Working version" 2>&1
        }

        # Commit 6: INTRODUCE BUG (divides by zero)
        @'
function Get-Value {
    param([int]$x)
    return $x / 0  # BUG: Division by zero
}
'@ | Set-Content $functionPath
        git add $functionPath
        $null = git commit -m 'Commit 6: BUG INTRODUCED - division by zero' 2>&1

        # Commits 7-10: Bug remains
        7..10 | ForEach-Object {
            $commitNum = $_
            @'
function Get-Value {
    param([int]$x)
    return $x / 0  # Bug persists
}
'@ | Set-Content $functionPath
            git add $functionPath
            $null = git commit -m "Commit $commitNum`: Bug still present" 2>&1
        }

        # All commits have been created successfully
    }

    It 'Should find commit 6 as the bad commit using bisect' {
        # Get commit hashes in the test
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit10 = git log --format=%H | Select-Object -First 1
        $commit6Subject = 'Commit 6: BUG INTRODUCED - division by zero'

        # Verify we got the expected commits
        $commit1 | Should -Not -BeNullOrEmpty
        $commit10 | Should -Not -BeNullOrEmpty

        # Start bisect: commit 1 is good, commit 10 is bad
        $iterations = @()
        $result = Start-GitBisect -Good $commit1 -Bad $commit10 -ScriptBlock {
            # Test the function
            try
            {
                . ./MyFunction.ps1
                $result = Get-Value -x 10
                $global:GitBisectExitCodes = @(0)  # Success
            } catch
            {
                # Function threw error - bad commit
                $global:GitBisectExitCodes = @(1)
            }
        } | ForEach-Object {
            # Collect iteration objects
            if ($_.PSObject.Properties.Match('Iteration').Count -gt 0)
            {
                $iterations += $_
            }
            # Return all objects for final result
            $_
        } | Select-Object -Last 1

        # Verify result object structure
        $result | Should -Not -BeNullOrEmpty
        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $commit6Subject
        $result.Iterations | Should -BeGreaterThan 0
        $result.PSObject.Properties.Name | Should -Contain 'ShortHash'
        $result.PSObject.Properties.Name | Should -Contain 'CommitSubject'
        $result.PSObject.Properties.Name | Should -Contain 'CommitAuthor'

        # Verify iteration objects were output
        $iterations.Count | Should -BeGreaterThan 0
        $iterations[0].PSObject.Properties.Name | Should -Contain 'CommitHash'
        $iterations[0].PSObject.Properties.Name | Should -Contain 'ShortHash'
        $iterations[0].PSObject.Properties.Name | Should -Contain 'TestResult'
        $iterations[0].PSObject.Properties.Name | Should -Contain 'Duration'

        # Verify git bisect found commit 6
        $currentCommitSubject = git log --format=%s -1
        $currentCommitSubject | Should -Be $commit6Subject
    }

    It 'Should output rich iteration objects with all expected properties' {
        # Get commit hashes
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit10 = git log --format=%H | Select-Object -First 1

        # Collect iteration objects
        $iterations = @()
        Start-GitBisect -Good $commit1 -Bad $commit10 -ScriptBlock {
            try
            {
                . ./MyFunction.ps1
                Get-Value -x 10 | Out-Null
                $global:GitBisectExitCodes = @(0)
            } catch
            {
                $global:GitBisectExitCodes = @(1)
            }
        } | ForEach-Object {
            if ($_.PSObject.Properties.Match('Iteration').Count -gt 0)
            {
                $iterations += $_
            }
        }

        # Verify we got iterations
        $iterations.Count | Should -BeGreaterThan 0

        # Check first iteration has all required properties
        $firstIteration = $iterations[0]
        $firstIteration.Iteration | Should -BeGreaterThan 0
        $firstIteration.CommitHash | Should -Not -BeNullOrEmpty
        $firstIteration.ShortHash | Should -Not -BeNullOrEmpty
        $firstIteration.CommitSubject | Should -Not -BeNullOrEmpty
        $firstIteration.CommitAuthor | Should -Not -BeNullOrEmpty
        $firstIteration.CommitDate | Should -Not -BeNullOrEmpty
        $firstIteration.TestResult | Should -BeIn @('good', 'bad', 'skip')
        $firstIteration.Duration | Should -Not -BeNullOrEmpty
        $firstIteration.ExitCodes | Should -Not -BeNullOrEmpty

        # Check that completion marker exists on final iteration
        $finalIteration = $iterations | Select-Object -Last 1
        $finalIteration.PSObject.Properties.Name | Should -Contain 'IsComplete'
        $finalIteration.IsComplete | Should -Be $true
        $finalIteration.PSObject.Properties.Name | Should -Contain 'FirstBadCommit'
        $finalIteration.FirstBadCommit | Should -Not -BeNullOrEmpty
    }

    It 'Should handle untestable commits with SkipRegex' {
        # Get commit hashes in the test (before adding new commits)
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit6Subject = 'Commit 6: BUG INTRODUCED - division by zero'

        # Add an untestable commit (missing dependency)
        @'
# Missing dependency - should be skipped
throw 'Missing required module'
'@ | Set-Content './MyFunction.ps1'
        git add './MyFunction.ps1'
        git commit -m 'Commit 11: Untestable - missing dependency' | Out-Null

        $result = Start-GitBisect -Good $commit1 -Bad HEAD -ScriptBlock {
            try
            {
                . ./MyFunction.ps1
                Get-Value -x 10
                $global:GitBisectExitCodes = @(0)
            } catch
            {
                if ($_ -match 'Missing required module')
                {
                    $global:GitBisectExitCodes = @(125)
                } else
                {
                    $global:GitBisectExitCodes = @(1)
                }
            }
        } -SkipRegex 'Missing required module' | Select-Object -Last 1

        # Verify result
        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $commit6Subject

        # Should skip commit 11 and find commit 6
        $currentCommit = git log --format=%s -1
        $currentCommit | Should -Be $commit6Subject
    }

    It 'Should handle untestable commits with SkipScriptBlock' {
        # Get commit hashes in the test (before adding new commits)
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit6Subject = 'Commit 6: BUG INTRODUCED - division by zero'

        # Add an untestable commit (no tests to run)
        @'
# No tests in this commit
'@ | Set-Content './MyFunction.ps1'
        git add './MyFunction.ps1'
        git commit -m 'Commit 12: Untestable - no tests' | Out-Null

        $result = Start-GitBisect -Good $commit1 -Bad HEAD -ScriptBlock {
            try
            {
                . ./MyFunction.ps1

                # Check if there are any tests defined
                if (-not (Get-Command Get-Value -ErrorAction SilentlyContinue))
                {
                    $global:GitBisectExitCodes = @(125)
                } else
                {
                    Get-Value -x 10
                    $global:GitBisectExitCodes = @(0)
                }
            } catch
            {
                $global:GitBisectExitCodes = @(1)
            }
        } -SkipScriptBlock {
            param($Output, $ExitCodes)
            # Skip if exit code 125 was set
            $ExitCodes -contains 125
        } | Select-Object -Last 1

        # Verify result
        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $commit6Subject

        # Should find commit 6 (skipping commit 12)
        $currentCommitSubject = git log --format=%s -1
        $currentCommitSubject | Should -Be $commit6Subject
    }

    It 'Should support boolean return values (false=good, true=bad)' {
        # Get existing commits (1-10 with bug at 6)
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit10 = git log --format=%H | Select-Object -First 1
        $commit6Subject = 'Commit 6: BUG INTRODUCED - division by zero'

        $result = Start-GitBisect -Good $commit1 -Bad $commit10 -ScriptBlock {
            try
            {
                . ./MyFunction.ps1
                Get-Value -x 10 | Out-Null
                $false  # Good (no error)
            } catch
            {
                $true  # Bad (error occurred)
            }
        } | Select-Object -Last 1

        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $commit6Subject
    }

    It 'Should support integer return values (0=good, non-zero=bad)' {
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit10 = git log --format=%H | Select-Object -First 1
        $commit6Subject = 'Commit 6: BUG INTRODUCED - division by zero'

        $result = Start-GitBisect -Good $commit1 -Bad $commit10 -ScriptBlock {
            try
            {
                . ./MyFunction.ps1
                Get-Value -x 10 | Out-Null
                0  # Good
            } catch
            {
                1  # Bad
            }
        } | Select-Object -Last 1

        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $commit6Subject
    }

    It 'Should handle sequential commit scenario (like /tmp/bisect)' {
        # Create 19 commits with sequential numbers
        for ($i = 1; $i -le 19; $i++)
        {
            "$i" | Set-Content './numbers.txt'
            git add './numbers.txt'
            $null = git commit -m "$i commit" 2>&1
        }

        $commitsReverse = git log --reverse --format=%H | Select-Object -First 19
        $commit1 = $commitsReverse[0]
        $commit19 = git log --format=%H | Select-Object -First 1
        $expectedBad = '14 commit'

        $result = Start-GitBisect -Good $commit1 -Bad $commit19 -ScriptBlock {
            $num = [int](Get-Content './numbers.txt')
            $num -ge 14  # true = bad (14+), false = good (1-13)
        } | Select-Object -Last 1

        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $expectedBad
        $result.Iterations | Should -BeGreaterThan 0
    }

    It 'Should support skip via return value 125' {
        # Create a simple test scenario
        # Commits 1-5 good, 6-10 bad (similar to existing setup)
        for ($i = 11; $i -le 12; $i++)
        {
            if ($i -eq 11)
            {
                # Untestable commit
                'MISSING' | Set-Content './skip-test.txt'
            } else
            {
                # Bad commit (after untestable)
                'bad' | Set-Content './skip-test.txt'
            }
            git add './skip-test.txt'
            $null = git commit -m "Skip test commit $i" 2>&1
        }

        $commitsReverse = git log --reverse --format=%H | Select-Object -First 12
        $commit1 = $commitsReverse[0]
        $commit12 = git log --format=%H | Select-Object -First 1
        $commit6Subject = 'Commit 6: BUG INTRODUCED - division by zero'

        $result = Start-GitBisect -Good $commit1 -Bad $commit12 -ScriptBlock {
            # Check if we're testing commit 11 (untestable)
            $subject = git log --format=%s -1
            if ($subject -match 'Skip test commit 11')
            {
                return 125  # Skip this commit
            }

            # Normal test logic
            try
            {
                . ./MyFunction.ps1
                Get-Value -x 10 | Out-Null
                0  # Good
            } catch
            {
                1  # Bad
            }
        } | Select-Object -Last 1

        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $commit6Subject
    }

    It 'Should maintain backward compatibility with GitBisectExitCodes' {
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit10 = git log --format=%H | Select-Object -First 1
        $commit6Subject = 'Commit 6: BUG INTRODUCED - division by zero'

        $result = Start-GitBisect -Good $commit1 -Bad $commit10 -ScriptBlock {
            try
            {
                . ./MyFunction.ps1
                Get-Value -x 10 | Out-Null
                $global:GitBisectExitCodes = @(0)  # Good
            } catch
            {
                $global:GitBisectExitCodes = @(1)  # Bad
            }
        } | Select-Object -Last 1

        $result.Success | Should -Be $true
        $result.CommitSubject | Should -Be $commit6Subject
    }

    AfterEach {
        # Clean up bisect state
        if (Test-Path '.git/BISECT_LOG')
        {
            Write-Verbose "Resetting git bisect state"
            git bisect reset 2>&1 | Out-Null
        }

        Pop-Location
    }
}
