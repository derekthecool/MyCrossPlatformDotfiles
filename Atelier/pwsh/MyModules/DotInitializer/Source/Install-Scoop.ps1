function Install-Scoop
{
    if(-not $(Get-Command scoop.ps1 -ErrorAction SilentlyContinue))
    {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        scoop bucket add extras
    }
}
