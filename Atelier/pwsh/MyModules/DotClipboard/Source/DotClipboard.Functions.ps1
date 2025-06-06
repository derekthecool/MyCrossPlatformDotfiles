function Get-ClipboardAsArray
{
    (Get-Clipboard) -split "[`n`r`t, ]+"
}

New-Alias -Name 'clipped' -Value Get-ClipboardAsArray
