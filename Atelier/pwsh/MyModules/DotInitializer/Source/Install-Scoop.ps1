function Install-Scoop
{
    if(-not $(Get-Command scoop.ps1 -ErrorAction SilentlyContinue))
    {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

        # The only additional bucket for my needs
        scoop bucket add extras

        # Required for extras bucket
        scoop install git
    }
}
