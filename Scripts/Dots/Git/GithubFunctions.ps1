function Get-LatestGithubRelease
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('\w+/\w+')]
        [string]$Repo
    )
    Invoke-WebRequest -Uri "https://api.github.com/repos/${Repo}/releases/latest"
    | ConvertFrom-Json
    | Select-Object -ExpandProperty assets
    | Select-Object -ExpandProperty browser_download_url
}
