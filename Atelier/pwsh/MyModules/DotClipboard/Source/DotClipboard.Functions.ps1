<#
.SYNOPSIS
Parses clipboard text into an array with optional filtering, splitting, transformation, and output formatting.

.DESCRIPTION
Get-ClipboardAsArray retrieves text from the system clipboard, splits it into items using a customizable
separator pattern, optionally filters each item using a regular expression, and optionally transforms each
item using a user-supplied scriptblock. The output can be returned as a normal array, or formatted as JSON,
SQL query lists, or SQL INSERT-ready values.

By default, the clipboard content is split using the regex pattern "[`n`r`t, ]+" which separates on typical
newline, tab, comma, and space delimiters. The -MatchFilter parameter allows filtering of split elements,
and -Transform allows arbitrary conversion logic such as casting to integers, converting hex strings to bytes,
or performing custom parsing.

If -ReloadClipboard is specified, the function explicitly reloads the clipboard to ensure fresh content,
useful when clipboard state changes rapidly.

Different parameter sets enable alternate output modes:
- Default: output transformed array items
- Json: output items as JSON text
- Describe: return metadata about how the clipboard would be parsed
- AsSqlQueryList: output a comma-separated SQL-safe list (e.g., 'a','b','c')
- AsSqlInsert: output values suitable for SQL INSERT statements

.PARAMETER Separator
A regex pattern used to split clipboard text into array elements. Default: "[`n`r`t, ]+".

.PARAMETER MatchFilter
A regex filter applied to each split element. Only matching items are kept. Default: ".*" (keep all).

.PARAMETER Transform
A scriptblock (as a string) that is executed for each element. The current item is represented by $_.
Useful for converting to numbers, bytes, objects, etc.
.EXAMPLE
Get-ClipboardAsArray -Transform {[int]$args[0]}

.PARAMETER TypeTransform
A shortcut approach to Transform. If argument is supplied then the Transform scriptblock
is overridden and will just convert the type
.EXAMPLE
# NOTE: if just [int] is passed it will be parsed as a string
# the type must be wrapped in () e.g. (int)
Get-ClipboardAsArray -Transform ([int])

.PARAMETER ReloadClipboard
Reloads the clipboard content before processing. Aliases: -Reclip, -R.

.PARAMETER Json
Formats the output array as JSON. Parameter set: Json.

.PARAMETER Describe
Returns a description of how the clipboard will be parsed rather than the parsed output. 
Parameter set: Describe.

.PARAMETER AsSqlQueryList
Formats items as a SQL 'IN' list (e.g., 'value1','value2','value3'). Parameter set: AsSqlQueryList.
Aliases: -asq, -sql.

.PARAMETER AsSqlInsert
Formats items for SQL INSERT value lists. Parameter set: AsSqlInsert.
Aliases: -asi, -si, -SqlInsert.

.EXAMPLE
Get-ClipboardAsArray

Splits the clipboard text using the default separator and returns the array of items.

.EXAMPLE
Get-ClipboardAsArray -Transform { [int]$_ }

Converts each clipboard item into an integer.

.EXAMPLE
Get-ClipboardAsArray -MatchFilter '^[A-F0-9]{2}$' -Transform { [byte]("0x$_") }

Extracts only hex byte values from the clipboard and converts them to [byte] objects.

.EXAMPLE
Get-ClipboardAsArray -AsSqlQueryList

Returns clipboard items formatted as: 'item1','item2','item3'

.EXAMPLE
Get-ClipboardAsArray -Json

Returns clipboard items as a JSON array.

.INPUTS
None. Clipboard content is used.

.OUTPUTS
Object[]
String (JSON mode)
String (SQL modes)
HashTable (Describe mode)

.NOTES
The -Transform parameter expects a scriptblock expression passed as a string. Example:
    -Transform { $_.Trim().ToUpper() }
The scriptblock is invoked for each element after filtering.

#>
function Get-ClipboardAsArray
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, ParameterSetName = '__AllParameterSets')]
        [string]$Separator = "[`n`r`t, ]+",

        [Parameter(ParameterSetName = '__AllParameterSets')]
        [string]$MatchFilter = ".*",

        [Parameter(ParameterSetName = '__AllParameterSets')]
        [scriptblock]$Transform = { $_ },

        [Parameter(ParameterSetName = '__AllParameterSets')]
        [Alias('Type', 'T')]
        [type]$TypeTransform,

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

    Write-Debug "Transform type: $($Transform.GetType().FullName)"

    # Allow for easy type conversion by supplying a type
    $Transform = {
        param($x, $t)

        if ($t)
        {
            $t::Parse($x)
        } else
        {
            $x
        }
    }

    $items = (Get-Clipboard) -split $Separator |
        Where-Object { $_ -match '\S' -and $_ -cmatch $MatchFilter } |
        ForEach-Object { $_.Trim() } |
        ForEach-Object { Invoke-Command -ScriptBlock $Transform -ArgumentList $_ }

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
