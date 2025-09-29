function Get-ClipboardAsArray
{
    param (
        [Parameter(Position = 0)]
        [string]$Separator = "[`n`r`t, ]+",
        [switch]$Json,
        [switch]$Describe,
        [switch]$AsSqlQueryList
    )

    $items = (Get-Clipboard) -split $Separator | Where-Object { -not [string]::IsNullOrEmpty($_) }

    if($Describe)
    {
        Write-Host "Count : $($items.Length)" -ForegroundColor Blue
    }

    if ($Json -or $AsSqlQueryList)
    {
        $items = $items | ConvertTo-Json -Compress
        if($AsSqlQueryList)
        {
            $items = $items.TrimStart("[").TrimEnd("]")
        }
    }
  
    $items
}

New-Alias -Name 'clipped' -Value Get-ClipboardAsArray
