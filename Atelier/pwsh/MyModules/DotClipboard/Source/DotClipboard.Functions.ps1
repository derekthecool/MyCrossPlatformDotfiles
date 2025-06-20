function Get-ClipboardAsArray
{
    param (
        [Parameter(Position = 0)]
        [string]$Separator = "[`n`r`t, ]+",
        [switch]$Json
    )

    $items = (Get-Clipboard) -split $Separator | Where-Object { -not [string]::IsNullOrEmpty($_) }

    if ($Json)
    {
        $items | ConvertTo-Json -Compress
    } else
    {
        $items
    }
}

New-Alias -Name 'clipped' -Value Get-ClipboardAsArray
