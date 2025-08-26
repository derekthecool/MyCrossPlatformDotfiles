function Get-GitWorktree
{
    git worktree list | ConvertFrom-Text '(?<Path>\S+)\s+\w+\s\[(?<Name>\w+)\]'
}

New-Alias -Name 'gwt' -Value Get-GitWorktree

function Switch-GitWorktree
{
    $trees = Get-GitWorktree
    if($trees)
    {
        Set-Location $($trees | Select-Object -ExpandProperty Path | Invoke-Fzf)
    }
    else
    {
        Write-Error "No git worktrees found"
    }
  
}

New-Alias -Name 'swt' -Value Switch-GitWorktree
