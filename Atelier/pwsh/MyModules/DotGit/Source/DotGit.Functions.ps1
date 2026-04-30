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
        and optionally running automated validation scriptblocks to test each commit. The function handles
        exit codes properly (0=good, 1=bad, 125=skip) and supports skip detection via regex or advanced scriptblock logic.

    .PARAMETER ScriptBlock
        The scriptblock to execute for each commit being tested. Should contain validation steps to test the commit.
        Users should populate $global:GitBisectExitCodes with exit codes from external commands.

    .PARAMETER GoodCommitHash
        The known-good commit hash. If not provided, assumes bisect is already started.

    .PARAMETER BadCommitHash
        The known-bad commit hash. If not provided, assumes bisect is already started.

    .PARAMETER SkipRegex
        Mutually exclusive with SkipScriptBlock. Regex pattern to match against stdout/stderr from all commands.
        If match found, the commit is skipped (exit 125).

    .PARAMETER SkipScriptBlock
        Mutually exclusive with SkipRegex. Advanced skip logic that receives collected output and exit codes.
        Should return $true to skip (exit 125) or $false to continue.

    .EXAMPLE
        # Initialize bisect with good and bad commits
        Start-GitBisect -Good abc123 -Bad def456

    .EXAMPLE
        # Run automated bisect with scriptblock
        Start-GitBisect -Good HEAD~10 -Bad HEAD -ScriptBlock {
            npm test
            $global:GitBisectExitCodes += $LASTEXITCODE
        }

    .EXAMPLE
        # Skip commits that match a regex pattern
        Start-GitBisect -ScriptBlock { ./build.sh } -SkipRegex 'compilation failed'

    .EXAMPLE
        # Skip commits with custom logic
        Start-GitBisect -ScriptBlock { ./test.sh } -SkipScriptBlock {
            param($Output, $ExitCodes)
            $Output -match 'no tests in commit'
        }
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
                    return $false
                }

                Write-Verbose "Git bisect iteration $iterationCount"
                $currentCommit = git log --format=%H -1
                Write-Verbose "Testing commit: $currentCommit"

                # Initialize for this iteration
                $global:GitBisectExitCodes = @()
                $outputBuilder = [System.Text.StringBuilder]::new()
                $powerShellError = $false

                try
                {
                    # Execute scriptblock and capture output
                    Invoke-Command -ScriptBlock $ScriptBlock 2>&1 |
                        ForEach-Object {
                            $outputBuilder.AppendLine($_.ToString()) | Out-Null
                            $_
                        } | Out-Null

                    $capturedOutput = $outputBuilder.ToString()

                    # Check skip detection
                    $shouldSkip = $false

                    if ($SkipScriptBlock)
                    {
                        Write-Verbose 'Executing SkipScriptBlock'
                        $shouldSkip = & $SkipScriptBlock $capturedOutput $global:GitBisectExitCodes
                    }
                    elseif ($SkipRegex -and $capturedOutput -match $SkipRegex)
                    {
                        Write-Verbose "SkipRegex matched: $SkipRegex"
                        $shouldSkip = $true
                    }

                    # Determine git bisect result
                    if ($shouldSkip)
                    {
                        Write-Verbose 'Skipping commit'
                        & git bisect skip 2>&1 | Out-Null
                    }
                    elseif ($global:GitBisectExitCodes.Count -gt 0)
                    {
                        # User provided exit codes
                        Write-Verbose "Evaluating exit codes: $($global:GitBisectExitCodes -join ', ')"

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
                            Write-Verbose 'Marking as bad'
                            & git bisect bad 2>&1 | Out-Null
                        }
                        else
                        {
                            Write-Verbose 'Marking as good'
                            & git bisect good 2>&1 | Out-Null
                        }
                    }
                    else
                    {
                        # No exit codes, use PowerShell status
                        if ($?)
                        {
                            Write-Verbose 'Marking as good (PowerShell succeeded)'
                            & git bisect good 2>&1 | Out-Null
                        }
                        else
                        {
                            Write-Verbose 'Marking as bad (PowerShell failed)'
                            & git bisect bad 2>&1 | Out-Null
                        }
                    }

                    # Check if bisect is complete
                    # Git bisect creates BISECT_EXPECTED_REV when it has identified the first bad commit
                    if (Test-Path '.git/BISECT_EXPECTED_REV')
                    {
                        $expectedRev = Get-Content '.git/BISECT_EXPECTED_REV' -Raw
                        Write-Host "Bisect complete: First bad commit is $expectedRev"
                        break
                    }
                }
                catch
                {
                    Write-Verbose "Scriptblock threw exception, marking as bad"
                    & git bisect bad 2>&1 | Out-Null
                }
                finally
                {
                    # Clean up global variable
                    if (Test-Path variable:global:GitBisectExitCodes)
                    {
                        Remove-Variable -Name 'GitBisectExitCodes' -Scope Global -Force
                    }
                }
            }

            return $true
        }
    }
}
