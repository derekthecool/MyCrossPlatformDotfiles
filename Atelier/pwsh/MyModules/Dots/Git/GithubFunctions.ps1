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
