# AST scanning and manifest text editing used by Update-ModuleManifestExport.

function Get-ModuleSourceExport
{
    <#
    .SYNOPSIS
    Finds the functions and aliases a set of .ps1 files would export, skipping any 'private' folder.

    .DESCRIPTION
    Adapted from a psakefile task (Set-ModuleManifestFunctionsAndAliases). Parses each
    file with the PowerShell AST and collects top-level function names, Set-Alias/New-Alias names and
    [Alias()] attributes on a function's param block. Nested helper functions are not reported.

    .PARAMETER Path
    .ps1 files and/or directories (searched recursively).

    .EXAMPLE
    Get-ModuleSourceExport -Path ./MyModule/Source

    .OUTPUTS
    PSCustomObject with Function and Alias string arrays (sorted, unique).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Path
    )

    $files = foreach ($item in $Path)
    {
        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($item)
        if (Test-Path -LiteralPath $resolved -PathType Container)
        {
            Get-ChildItem -LiteralPath $resolved -File -Filter '*.ps1' -Recurse |
                Where-Object { $_.DirectoryName -notmatch '[\\/]private([\\/]|$)' }
        } elseif (Test-Path -LiteralPath $resolved -PathType Leaf)
        {
            Get-Item -LiteralPath $resolved
        } else
        {
            throw "Source path not found: $resolved"
        }
    }

    $functions = [System.Collections.Generic.List[string]]::new()
    $aliases = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $files)
    {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
        if ($errors.Count -gt 0)
        {
            throw "Cannot scan $($file.FullName): $($errors[0].Message)"
        }

        $definitions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
        foreach ($definition in $definitions)
        {
            $functions.Add($definition.Name)
            $paramBlock = $definition.Body.ParamBlock
            if ($paramBlock)
            {
                foreach ($attribute in $paramBlock.Attributes | Where-Object { $_.TypeName.Name -eq 'Alias' })
                {
                    foreach ($argument in $attribute.PositionalArguments | Where-Object { $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] })
                    {
                        $aliases.Add($argument.Value)
                    }
                }
            }
        }

        $commands = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                @('Set-Alias', 'New-Alias') -contains $node.GetCommandName()
            }, $false)
        foreach ($command in $commands)
        {
            $name = $null
            for ($i = 1; $i -lt $command.CommandElements.Count; $i++)
            {
                $element = $command.CommandElements[$i]
                if ($element -is [System.Management.Automation.Language.CommandParameterAst])
                {
                    if ($element.ParameterName -eq 'Name' -and $i + 1 -lt $command.CommandElements.Count)
                    {
                        $next = $command.CommandElements[$i + 1]
                        if ($next -is [System.Management.Automation.Language.StringConstantExpressionAst])
                        {
                            $name = $next.Value
                        }
                    }
                } elseif (-not $name -and $element -is [System.Management.Automation.Language.StringConstantExpressionAst])
                {
                    $name = $element.Value
                }
            }
            if ($name)
            {
                $aliases.Add($name)
            }
        }
    }

    [pscustomobject]@{
        Function = @($functions | Sort-Object -Unique)
        Alias    = @($aliases | Sort-Object -Unique)
    }
}

function Set-ManifestExportArray
{
    <#
    .SYNOPSIS
    Rewrites one export array (FunctionsToExport/AliasesToExport) inside manifest text and returns the new text.

    .DESCRIPTION
    Only the array's own extent is replaced, so comments and every other key survive. In region mode the
    names live between '# BEGIN generated: <Region>' / '# END generated: <Region>' lines and the rest of the
    array is left alone. In full mode the array is replaced wholesale.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [ValidateSet('FunctionsToExport', 'AliasesToExport')]
        [string]$Key,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$Name = @(),

        [Parameter()]
        [string]$Region
    )

    $newline = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0)
    {
        throw "Manifest does not parse: $($errors[0].Message)"
    }
    $table = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.HashtableAst] }, $false)
    if (-not $table)
    {
        throw 'Manifest does not contain a top-level hashtable.'
    }
    $pair = $table.KeyValuePairs | Where-Object { $_.Item1.Extent.Text.Trim("'", '"') -eq $Key } | Select-Object -First 1

    $quoted = @($Name | Sort-Object -Unique | ForEach-Object { "'" + $_.Replace("'", "''") + "'" })

    if (-not $pair)
    {
        if ($quoted.Count -eq 0)
        {
            return $Text
        }
        $closing = $table.Extent.EndOffset - 1
        $lineStart = $Text.LastIndexOf("`n", $closing) + 1
        $keyIndent = '    '
        $block = @("$keyIndent$Key = @(")
        if ($Region)
        {
            $block += "$keyIndent    # BEGIN generated: $Region"
        }
        $block += $quoted | ForEach-Object { "$keyIndent    $_" }
        if ($Region)
        {
            $block += "$keyIndent    # END generated: $Region"
        }
        $block += "$keyIndent)"
        return $Text.Substring(0, $lineStart) + ($block -join $newline) + $newline + $Text.Substring($lineStart)
    }

    $valueExtent = $pair.Item2.Extent
    $original = $valueExtent.Text
    $keyLineStart = $Text.LastIndexOf("`n", [Math]::Max(0, $pair.Item1.Extent.StartOffset - 1)) + 1
    $keyIndent = $Text.Substring($keyLineStart, $pair.Item1.Extent.StartOffset - $keyLineStart)
    if ($keyIndent.Trim())
    {
        $keyIndent = '    '
    }

    # A manifest rewritten by Update-ModuleManifest (or a build that calls it) holds bare lists such as
    # FunctionsToExport = 'a', 'b' and AliasesToExport = 'gs' rather than @( ... ).
    $bareList = $false
    if ($original -match '^\s*@\(')
    {
        $inner = $original.Substring($original.IndexOf('(') + 1)
        $inner = $inner.Substring(0, $inner.LastIndexOf(')'))
    } elseif ($original -match "^\s*['`"][^'`"*]")
    {
        $inner = $original
        $bareList = $true
    } elseif ($original -match "^\s*(''|`"`")?\s*$")
    {
        $inner = ''
    } elseif ($Region)
    {
        throw "$Key is '$($original.Trim())'. Region updates need an explicit list (lazy loading requires named exports)."
    } else
    {
        $inner = ''
    }

    if ($Region)
    {
        $escaped = [regex]::Escape($Region)
        $inner = [regex]::Replace($inner, "(?ms)^[ \t]*# BEGIN generated: $escaped[ \t]*\r?\n.*?^[ \t]*# END generated: $escaped[ \t]*(\r?\n|$)", '')

        # Do not repeat a name that is already listed by hand elsewhere in the array.
        $handwritten = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($line in $inner -split "\r?\n")
        {
            foreach ($match in [regex]::Matches(($line -replace '#.*$', ''), "[^\s,@()'`"]+"))
            {
                $null = $handwritten.Add($match.Value)
            }
        }
        $quoted = @($Name | Sort-Object -Unique | Where-Object { -not $handwritten.Contains($_) } | ForEach-Object { "'" + $_.Replace("'", "''") + "'" })

        # A bare list that already names everything (the usual state after a build rebuilt the exports)
        # stays exactly as it is.
        if ($bareList -and $quoted.Count -eq 0)
        {
            return $Text
        }

        $itemIndent = $keyIndent + '    '
        foreach ($line in $inner -split "\r?\n")
        {
            if ($line.Trim())
            {
                $itemIndent = $line.Substring(0, $line.Length - $line.TrimStart().Length)
                break
            }
        }

        $kept = $inner.TrimEnd()
        $parts = [System.Collections.Generic.List[string]]::new()
        if ($kept.Trim())
        {
            $parts.Add($kept)
        }
        if ($quoted.Count -gt 0)
        {
            $parts.Add("$itemIndent# BEGIN generated: $Region")
            foreach ($item in $quoted)
            {
                $parts.Add("$itemIndent$item")
            }
            $parts.Add("$itemIndent# END generated: $Region")
        }
        $replacement = if ($parts.Count -eq 0) { '@()' } else { '@(' + $newline + ($parts -join $newline).TrimStart("`r", "`n") + $newline + $keyIndent + ')' }
    } else
    {
        $replacement = if ($quoted.Count -eq 0) { '@()' } else { '@(' + $newline + (($quoted | ForEach-Object { "$keyIndent    $_" }) -join $newline) + $newline + $keyIndent + ')' }
    }

    $Text.Substring(0, $valueExtent.StartOffset) + $replacement + $Text.Substring($valueExtent.EndOffset)
}
