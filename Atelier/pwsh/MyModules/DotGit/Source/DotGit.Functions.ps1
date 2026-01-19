function Get-GitWorktree
{
    git worktree list | ConvertFrom-Text '(?<Path>\S+)\s+\w+\s\[(?<Name>\w+)\]'
}

New-Alias -Name 'gwt' -Value Get-GitWorktree

function Switch-GitWorktree
{
    $trees = Get-GitWorktree
    if ($trees)
    {
        Set-Location $($trees | Select-Object -ExpandProperty Path | Invoke-Fzf)
    } else
    {
        Write-Error "No git worktrees found"
    }
  
}

New-Alias -Name 'swt' -Value Switch-GitWorktree

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
