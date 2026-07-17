# GitHub CLI ships its own PowerShell completion; invoke it if gh is on PATH.
if (Get-Command gh -ErrorAction SilentlyContinue)
{
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
}
