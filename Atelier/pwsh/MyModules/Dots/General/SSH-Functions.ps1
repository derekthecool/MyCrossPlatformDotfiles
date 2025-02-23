function Connect-SSH
{
    $SelectedHost = Get-Content ~/.ssh/known_hosts
    | ConvertFrom-Text '(?<Host>^\S+)'
    | Select-Object -ExpandProperty Host -Unique
    | Invoke-Fzf -Prompt 'ssh host'

    & ssh $SelectedHost
}
