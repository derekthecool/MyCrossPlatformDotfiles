function Get-ClipboardAsArray
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, ParameterSetName = '__AllParameterSets')]
        [string]$Separator = "[`n`r`t, ]+",

        [Parameter(ParameterSetName = '__AllParameterSets')]
        [Alias('Reclip', 'R')]
        [switch]$ReloadClipboard,

        [Parameter(ParameterSetName = 'Json')]
        [switch]$Json,

        [Parameter(ParameterSetName = 'Describe')]
        [switch]$Describe,

        [Parameter(ParameterSetName = 'AsSqlQueryList')]
        [Alias('asq', 'sql')]
        [switch]$AsSqlQueryList,

        [Parameter(ParameterSetName = 'AsSqlInsert')]
        [Alias('asi', 'si', 'SqlInsert')]
        [switch]$AsSqlInsert
    )

    $items = (Get-Clipboard) -split $Separator | Where-Object { -not [string]::IsNullOrEmpty($_) }

    $result = switch ($PSCmdlet.ParameterSetName)
    {
        'Default' { $items }
        'Describe' { Write-Host "Count : $($items.Length)" -ForegroundColor Blue }
        'Json' { $items | ConvertTo-Json -Compress }
        'AsSqlQueryList' { ($items | ConvertTo-Json -Compress).TrimStart("[").TrimEnd("]") }
        'AsSqlInsert' { $items | ForEach-Object { "(`"$_`")" } | Join-String -Separator "," } 
    }

    if ($ReloadClipboard)
    {
        $result | Set-Clipboard
    }
    $result
}

New-Alias -Name 'clipped' -Value Get-ClipboardAsArray
