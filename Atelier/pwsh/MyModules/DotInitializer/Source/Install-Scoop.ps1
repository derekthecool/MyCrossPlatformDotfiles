function Install-Scoop
{
    if(-not $(Get-Command scoop.ps1 -ErrorAction SilentlyContinue))
    {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

        # The only additional bucket for my needs
        scoop bucket add extras

        # Install git if needed - this is needed for packages in the extras and versions buckets
        if(-not $(Get-Command git -ErrorAction SilentlyContinue))
        {
            scoop install git
        }

        # Install winget if needed - it is not installed by default on CI servers
        if(-not $(Get-Command winget -ErrorAction SilentlyContinue))
        {
            scoop install main/winget
        }
    }
}
