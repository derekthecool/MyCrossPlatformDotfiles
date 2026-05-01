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
        $commit6 = $commitsReverse[5]

        # Verify we got the expected commits
        $commit1 | Should -Not -BeNullOrEmpty
        $commit10 | Should -Not -BeNullOrEmpty
        $commit6 | Should -Not -BeNullOrEmpty

        # Start bisect: commit 1 is good, commit 10 is bad
        Start-GitBisect -Good $commit1 -Bad $commit10 -ScriptBlock {
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
        }

        # Verify git bisect found commit 6
        $currentCommit = git log --format=%H | Select-Object -First 1
        $currentCommit | Should -Be $commit6
    }

    It 'Should handle untestable commits with SkipRegex' {
        # Get commit hashes in the test (before adding new commits)
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit6 = $commitsReverse[5]

        # Add an untestable commit (missing dependency)
        @'
# Missing dependency - should be skipped
throw 'Missing required module'
'@ | Set-Content './MyFunction.ps1'
        git add './MyFunction.ps1'
        git commit -m 'Commit 11: Untestable - missing dependency' | Out-Null

        Start-GitBisect -Good $commit1 -Bad HEAD -ScriptBlock {
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
        } -SkipRegex 'Missing required module'

        # Should skip commit 11 and find commit 6
        $currentCommit = git log --format=%H | Select-Object -First 1
        $currentCommit | Should -Be $commit6
    }

    It 'Should handle untestable commits with SkipScriptBlock' {
        # Get commit hashes in the test (before adding new commits)
        $commitsReverse = git log --reverse --format=%H | Select-Object -First 10
        $commit1 = $commitsReverse[0]
        $commit6 = $commitsReverse[5]

        # Add an untestable commit (no tests to run)
        @'
# No tests in this commit
'@ | Set-Content './MyFunction.ps1'
        git add './MyFunction.ps1'
        git commit -m 'Commit 12: Untestable - no tests' | Out-Null

        Start-GitBisect -Good $commit1 -Bad HEAD -ScriptBlock {
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
        }

        # Should find commit 6 (skipping commit 12)
        $currentCommit = git log --format=%H | Select-Object -First 1
        $currentCommit | Should -Be $commit6
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
