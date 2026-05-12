<#
    .SYNOPSIS
    Runs git worktree list and returns a rich object

    .DESCRIPTION
    Returns the result of git worktree list but also collects the date the
    git worktree was last used. This useful for detecting which git worktrees
    are old and should be purged.

    .PARAMETER Name
    Specifies the file name.

    .EXAMPLE
    Get-GitWorktree
#>
function Get-GitWorktree
{
    [CmdletBinding()]
    [Alias('gwt')]
    param()

    git worktree list |
        ConvertFrom-Text '(?<Path>\S+)\s+\w+\s\[(?<Name>\w+)\]' |
        ForEach-Object {
            $treeDirectory = (Get-Content "$($_.Path)/.git") -split ' ' | Select-Object -Last 1
            $LastUsed = Get-ChildItem -Recurse -File $treeDirectory |
                Sort-Object LastWriteTime |
                Select-Object -Last 1 -ExpandProperty LastWriteTime
                [PSCustomObject]@{
                    Path     =$_.Path
                    Name     =$_.Name
                    LastUsed =$LastUsed
                }
            } |
            Sort-Object LastUsed
}

<#
    .SYNOPSIS
    Remove a git worktree

    .DESCRIPTION
    Takes input from Get-GitWorktree objects and will remove the git worktree.
    If the git worktree is not clean e.g. unstaged files it will not be deleted.

    .EXAMPLE
    # Delete the first 5 git worktrees found (these will be the oldest and last used)
    Get-GitWorktree | Select-Object -First 5 | Remove-GitWorktree

    .EXAMPLE
    # Delete all git worktrees that have not been used for the last 3 month
    Get-GitWorktree | Where-Object { $_.LastUsed -lt (Get-Date).AddMonths(-3) } | Remove-GitWorktree
#>
filter Remove-GitWorktree
{
    [Alias('rwt')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name
    )
    Write-Verbose "Removing git worktree $Name"
    & git worktree remove $Name
}

function Switch-GitWorktree
{
    [CmdletBinding()]
    [Alias('swt')]
    param()
    $trees = Get-GitWorktree
    if ($trees)
    {
        Set-Location $($trees | Select-Object -ExpandProperty Path | Invoke-Fzf)
    } else
    {
        Write-Error "No git worktrees found"
    }
}

<#
    .SYNOPSIS
    Use online gitignore templates

    .DESCRIPTION
    Easily download gitignore templates. Uses fzf and Invoke-Fzf to help you select the one you want.
    So really it is an interactive function.

    .PARAMETER Write
    If set the file will be written the current directory .gitignore

    .EXAMPLE
    PS> Add-Extension -name "File"
#>
function Get-GitIgnore
{
    param (
        [Parameter()]
        [switch]$Write
    )

    $AllTemplates = (Invoke-RestMethod https://www.toptal.com/developers/gitignore/api/list) -split ','
    $selected = $AllTemplates | Invoke-Fzf -Prompt 'Choose gitignore file'

    Write-Host "Selected gitignore: $selected"
    $gitignoreContent = Invoke-RestMethod -Uri "https://www.toptal.com/developers/gitignore/api/$selected"

    if ($Write)
    {
        Write-Host ".gitignore written"
        $gitignoreContent | Out-File -FilePath $(Join-Path -Path $pwd -ChildPath ".gitignore") -Encoding ascii
    } else
    {
        $gitignoreContent
    }
}

function Get-LatestGithubRelease
{
    <#
    .SYNOPSIS
    Gets the latest release information from a GitHub repository.

    .DESCRIPTION
    Fetches the latest release from a GitHub repository and returns a rich object
    with version information, assets, and release metadata. Maintains backward
    compatibility via the DownloadUrls property.

    .PARAMETER Repo
    The GitHub repository in 'owner/repo' format.

    .EXAMPLE
    Get-LatestGithubRelease -Repo 'opensteno/plover'

    .EXAMPLE
    # Backward compatible - get just download URLs
    $urls = (Get-LatestGithubRelease -Repo 'opensteno/plover').DownloadUrls

    .EXAMPLE
    # New usage - get rich release data
    $release = Get-LatestGithubRelease -Repo 'opensteno/plover'
    Write-Host "Latest version: $($release.TagName)"
    Write-Host "Assets: $($release.Assets.Count)"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('\w+/\w+')]
        [string]$Repo
    )

    $release = Invoke-RestMethod "https://api.github.com/repos/${Repo}/releases/latest"

    [PSCustomObject]@{
        TagName      = $release.tag_name           # Version (e.g., "v5.3.0")
        Name         = $release.name                # Release name
        HtmlUrl      = $release.html_url            # Release page URL
        PublishedAt  = $release.published_at        # Release date
        Body         = $release.body                # Release notes
        Assets       = $release.assets | ForEach-Object {
            [PSCustomObject]@{
                Name               = $_.name
                BrowserDownloadUrl = $_.browser_download_url
                Size               = $_.size
                ContentType        = $_.content_type
            }
        }
        DownloadUrls = $release.assets.browser_download_url  # Legacy property (backward compat)
    }
}

<#
    .SYNOPSIS
        Initialize and run git bisect with automated testing.

    .DESCRIPTION
        Start-GitBisect simplifies the git bisect workflow by initializing bisect with good/bad commits
        and optionally running automated validation scriptblocks to test each commit. The scriptblock return
        value determines the bisect result: integers (0=good, non-zero=bad, 125=skip), booleans ($false=good,
        $true=bad), or the string 'skip' to skip untestable commits.

    .PARAMETER ScriptBlock
        The scriptblock to execute for each commit being tested. Return values determine bisect action:
        - Integer: 0 = good, non-zero = bad, 125 = skip
        - Boolean: $false = good, $true = bad
        - String 'skip' = skip
        - Exception = bad

        For backward compatibility, you can still set $global:GitBisectExitCodes instead of returning a value.

    .PARAMETER GoodCommitHash
        The known-good commit hash. If not provided, assumes bisect is already started.

    .PARAMETER BadCommitHash
        The known-bad commit hash. If not provided, assumes bisect is already started.

    .PARAMETER SkipRegex
        Mutually exclusive with SkipScriptBlock. Regex pattern to match against stdout/stderr from all commands.
        If match found, the commit is skipped.

    .PARAMETER SkipScriptBlock
        Mutually exclusive with SkipRegex. Advanced skip logic that receives collected output and exit codes.
        Should return $true to skip or $false to continue.

    .EXAMPLE
        # Initialize bisect with good and bad commits
        Start-GitBisect -Good abc123 -Bad def456

    .EXAMPLE
        # Boolean return (PowerShell-idiomatic)
        Start-GitBisect -Good HEAD~10 -Bad HEAD -ScriptBlock {
            [int](Get-Content file.txt) -ge 14  # true = bad, false = good
        }

    .EXAMPLE
        # Integer return (exit code style)
        Start-GitBisect -Good HEAD~10 -Bad HEAD -ScriptBlock {
            npm test
            $LASTEXITCODE  # 0 = good, non-zero = bad
        }

    .EXAMPLE
        # Skip untestable commits
        Start-GitBisect -Good HEAD~10 -Bad HEAD -ScriptBlock {
            if (-not (Test-Path config.json)) { return 125 }  # Skip
            npm test
            $LASTEXITCODE
        }

    .EXAMPLE
        # Backward compatible (global variable)
        Start-GitBisect -Good HEAD~10 -Bad HEAD -ScriptBlock {
            try {
                npm test
                $global:GitBisectExitCodes = @(0)
            } catch {
                $global:GitBisectExitCodes = @(1)
            }
        }

    .EXAMPLE
        # Skip commits that match a regex pattern
        Start-GitBisect -ScriptBlock { ./build.sh } -SkipRegex 'compilation failed'
#>
function Start-GitBisect
{
    [CmdletBinding(DefaultParameterSetName = 'Initialize')]
    [Alias('bisect')]
    param(
        [Parameter(ParameterSetName = 'Run', Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(ParameterSetName = 'Initialize', Position = 0)]
        [Parameter(ParameterSetName = 'Run', Position = 0)]
        [Alias('Good')]
        [string]$GoodCommitHash,

        [Parameter(ParameterSetName = 'Initialize', Position = 1)]
        [Parameter(ParameterSetName = 'Run', Position = 1)]
        [Alias('Bad')]
        [string]$BadCommitHash,

        [Parameter(ParameterSetName = 'Run')]
        [string]$SkipRegex,

        [Parameter(ParameterSetName = 'Run')]
        [scriptblock]$SkipScriptBlock
    )

    begin
    {
        # Validate mutual exclusivity of SkipRegex and SkipScriptBlock
        if ($SkipRegex -and $SkipScriptBlock)
        {
            throw 'SkipRegex and SkipScriptBlock are mutually exclusive. Use only one.'
        }
    }

    process
    {
        # Initialize bisect if good/bad commits provided
        if ($GoodCommitHash -and $BadCommitHash)
        {
            Write-Verbose "Initializing git bisect: Good=$GoodCommitHash, Bad=$BadCommitHash"

            # Initialize bisect session
            $initResult = & git bisect start 2>&1
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to initialize git bisect: $initResult"
                return $false
            }

            # Mark commits as good/bad using step-by-step approach
            Write-Verbose "Marking $GoodCommitHash as good"
            $markGood = & git bisect good $GoodCommitHash 2>&1
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to mark good commit: $markGood"
                git bisect reset | Out-Null
                return $false
            }

            Write-Verbose "Marking $BadCommitHash as bad"
            $markBad = & git bisect bad $BadCommitHash 2>&1
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to mark bad commit: $markBad"
                git bisect reset | Out-Null
                return $false
            }

            # If only initializing (no scriptblock), return success
            if (-not $ScriptBlock)
            {
                return $true
            }
        }

        # Run bisect with scriptblock
        if ($ScriptBlock)
        {
            Write-Verbose 'Running git bisect with scriptblock'

            # Check if bisect is active
            if (-not (Test-Path '.git/BISECT_LOG'))
            {
                Write-Error 'Not in a git bisect session. Initialize with Good and Bad commits first.'
                return $false
            }

            # Manual bisect loop - execute scriptblock for each commit
            $iterationCount = 0
            $maxIterations = 100  # Safety limit to prevent infinite loops
            while (Test-Path '.git/BISECT_LOG')
            {
                $iterationCount++
                if ($iterationCount -gt $maxIterations)
                {
                    Write-Error "Git bisect exceeded maximum iteration count ($maxIterations). Resetting bisect state."
                    git bisect reset | Out-Null
                    return [PSCustomObject]@{ Success = $false; Error = "Exceeded maximum iteration count ($maxIterations)" }
                }

                $iterationStart = Get-Date
                $currentCommit = git log --format=%H -1
                $shortHash = git log --format=%h -1
                $commitSubject = git log --format=%s -1
                $commitAuthor = git log --format=%an -1
                $commitDate = git log --format=%ai -1

                Write-Verbose "Git bisect iteration $iterationCount - $shortHash - $commitSubject"

                # Initialize for this iteration
                $global:GitBisectExitCodes = @()
                $outputBuilder = [System.Text.StringBuilder]::new()
                $scriptblockResult = $null

                try
                {
                    # Execute scriptblock and capture output and return value
                    $output = Invoke-Command -ScriptBlock $ScriptBlock 2>&1
                    $capturedOutput = ($output | ForEach-Object {
                        $outputBuilder.AppendLine($_.ToString()) | Out-Null
                        $_
                    }) -join "`n"

                    # The return value is the last object in the pipeline
                    $scriptblockResult = if ($output.Count -gt 0) { $output[-1] } else { $null }

                    # Determine bisect action from return value or global variable
                    $bisectAction = $null

                    # Backward compatibility: check if global variable was set
                    if ($global:GitBisectExitCodes.Count -gt 0)
                    {
                        Write-Verbose "Using global GitBisectExitCodes (deprecated, use return value instead)"
                        $hasNonZero = $false
                        foreach ($code in $global:GitBisectExitCodes)
                        {
                            if ($code -ne 0)
                            {
                                $hasNonZero = $true
                                break
                            }
                        }

                        if ($hasNonZero)
                        {
                            # Check for 125 (skip code)
                            $has125 = $false
                            foreach ($code in $global:GitBisectExitCodes)
                            {
                                if ($code -eq 125)
                                {
                                    $has125 = $true
                                    break
                                }
                            }

                            if ($has125)
                            {
                                $bisectAction = 'skip'
                            } else
                            {
                                $bisectAction = 'bad'
                            }
                        } else
                        {
                            $bisectAction = 'good'
                        }
                    }
                    # Use return value if global variable wasn't set
                    elseif ($null -ne $scriptblockResult)
                    {
                        Write-Verbose "Evaluating scriptblock return value: $($scriptblockResult.GetType().Name)"

                        if ($scriptblockResult -is [int])
                        {
                            if ($scriptblockResult -eq 0)
                            {
                                $bisectAction = 'good'
                            } elseif ($scriptblockResult -eq 125)
                            {
                                $bisectAction = 'skip'
                            } else
                            {
                                $bisectAction = 'bad'
                            }
                        }
                        elseif ($scriptblockResult -is [bool])
                        {
                            $bisectAction = if ($scriptblockResult) { 'bad' } else { 'good' }
                        }
                        elseif ($scriptblockResult -is [string] -and $scriptblockResult -eq 'skip')
                        {
                            $bisectAction = 'skip'
                        }
                        else
                        {
                            throw "ScriptBlock returned unexpected type: $($scriptblockResult.GetType().Name). Expected int, bool, or 'skip'."
                        }
                    }
                    # No return value and no global variable - warn user
                    else
                    {
                        Write-Warning "ScriptBlock did not return a value and did not set `$global:GitBisectExitCodes. Assuming good. Use explicit return (0/1 or `$false/`$true) or set `$global:GitBisectExitCodes."
                        $bisectAction = 'good'
                    }

                    # Check skip detection via parameters (backward compatibility)
                    if ($bisectAction -ne 'skip')
                    {
                        if ($SkipScriptBlock)
                        {
                            Write-Verbose 'Executing SkipScriptBlock'
                            $shouldSkip = & $SkipScriptBlock $capturedOutput $global:GitBisectExitCodes
                            if ($shouldSkip) { $bisectAction = 'skip' }
                        } elseif ($SkipRegex -and $capturedOutput -match $SkipRegex)
                        {
                            Write-Verbose "SkipRegex matched: $SkipRegex"
                            $bisectAction = 'skip'
                        }
                    }

                    # Determine git bisect result and capture output
                    $bisectOutput = switch ($bisectAction)
                    {
                        'skip'
                        {
                            Write-Verbose 'Skipping commit'
                            & git bisect skip 2>&1
                        }
                        'bad'
                        {
                            Write-Verbose 'Marking as bad'
                            & git bisect bad 2>&1
                        }
                        'good'
                        {
                            Write-Verbose 'Marking as good'
                            & git bisect good 2>&1
                        }
                    }

                    # Determine test result for the iteration object
                    $testResult = $bisectAction

                    # Check for completion message in output
                    $firstBadCommit = $null
                    if ($bisectOutput -match '([a-f0-9]{40}) is the first bad commit')
                    {
                        # Use explicit regex matching to avoid $matches scoping issues
                        $match = [regex]::Match($bisectOutput, '([a-f0-9]{40}) is the first bad commit')
                        if ($match.Success)
                        {
                            $firstBadCommit = $match.Groups[1].Value
                        }
                    }

                    if ($firstBadCommit)
                    {

                        # Create final iteration object
                        $duration = (Get-Date) - $iterationStart
                        $iterationResult = [PSCustomObject]@{
                            Iteration      = $iterationCount
                            CommitHash     = $currentCommit
                            ShortHash      = $shortHash
                            CommitSubject  = $commitSubject
                            CommitAuthor   = $commitAuthor
                            CommitDate     = $commitDate
                            TestResult     = $testResult
                            TestOutput     = $capturedOutput.Trim()
                            ReturnValue    = if ($null -ne $scriptblockResult) { $scriptblockResult } else { $global:GitBisectExitCodes }
                            ExitCodes      = if ($global:GitBisectExitCodes) { $global:GitBisectExitCodes.Clone() } else { @() }
                            Duration       = $duration
                            IsComplete     = $true
                            FirstBadCommit = $firstBadCommit
                        }

                        Write-Output $iterationResult

                        # Get short hash for display
                        $shortHashResult = git log --format=%h -1 $firstBadCommit
                        Write-Host "✓ Bisect complete: First bad commit is $shortHashResult"
                        break
                    } else
                    {
                        # Not complete yet, create iteration object
                        $duration = (Get-Date) - $iterationStart
                        $iterationResult = [PSCustomObject]@{
                            Iteration      = $iterationCount
                            CommitHash     = $currentCommit
                            ShortHash      = $shortHash
                            CommitSubject  = $commitSubject
                            CommitAuthor   = $commitAuthor
                            CommitDate     = $commitDate
                            TestResult     = $testResult
                            TestOutput     = $capturedOutput.Trim()
                            ReturnValue    = if ($null -ne $scriptblockResult) { $scriptblockResult } else { $global:GitBisectExitCodes }
                            ExitCodes      = if ($global:GitBisectExitCodes) { $global:GitBisectExitCodes.Clone() } else { @() }
                            Duration       = $duration
                        }

                        Write-Output $iterationResult
                    }
                } catch
                {
                    Write-Verbose "Scriptblock threw exception, marking as bad"
                    $bisectOutput = & git bisect bad 2>&1

                    # Check if exception triggered completion
                    if ($bisectOutput -match '([a-f0-9]{40}) is the first bad commit')
                    {
                        # Use explicit regex matching to avoid $matches scoping issues
                        $match = [regex]::Match($bisectOutput, '([a-f0-9]{40}) is the first bad commit')
                        if ($match.Success)
                        {
                            $firstBadCommit = $match.Groups[1].Value
                            $duration = (Get-Date) - $iterationStart

                        $iterationResult = [PSCustomObject]@{
                            Iteration      = $iterationCount
                            CommitHash     = $currentCommit
                            ShortHash      = $shortHash
                            CommitSubject  = $commitSubject
                            CommitAuthor   = $commitAuthor
                            CommitDate     = $commitDate
                            TestResult     = 'bad'
                            TestOutput     = "Exception: $_"
                            ExitCodes      = @()
                            Duration       = $duration
                            IsComplete     = $true
                            FirstBadCommit = $firstBadCommit
                        }

                        Write-Output $iterationResult
                        break
                        }
                    }
                } finally
                {
                    # Clean up global variable
                    if (Test-Path variable:global:GitBisectExitCodes)
                    {
                        Remove-Variable -Name 'GitBisectExitCodes' -Scope Global -Force
                    }
                }
            }

            # Create and return final result object
            if (Test-Path '.git/BISECT_LOG')
            {
                $currentCommit = git log --format=%H -1
                $result = [PSCustomObject]@{
                    Success        = $true
                    FirstBadCommit = $currentCommit
                    ShortHash      = git log --format=%h -1
                    CommitSubject  = git log --format=%s -1
                    CommitAuthor   = git log --format=%an -1
                    CommitDate     = git log --format=%ai -1
                    Iterations     = $iterationCount
                    BisectLog      = git bisect log 2>&1
                }

                return $result
            }

            return [PSCustomObject]@{ Success = $false; Error = 'Bisect did not complete successfully' }
        }
    }
}
