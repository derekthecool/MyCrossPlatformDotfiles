if (Get-Command gh -ErrorAction SilentlyContinue)
{
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
}
