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
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('\w+/\w+')]
        [string]$Repo
    )
    Invoke-RestMethod "https://api.github.com/repos/${Repo}/releases/latest"
    | Select-Object -ExpandProperty assets
    | Select-Object -ExpandProperty browser_download_url
}
