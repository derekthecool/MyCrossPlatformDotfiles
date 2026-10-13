function Update-ModuleManifestExport
{
    <#
    .SYNOPSIS
    Updates FunctionsToExport / AliasesToExport in any module manifest (.psd1) without disturbing the rest of the file.

    .DESCRIPTION
    Lazy-loaded modules must list their exports in the manifest. Names come from -FunctionName/-AliasName
    and/or an AST scan of -SourcePath (private folders skipped, see Get-ModuleSourceExport).

    With -Region the names are written between BEGIN/END marker comments inside each array, leaving
    hand-maintained entries alone; running again replaces just that region, so removed functions drop out.
    With -Full each array is replaced by exactly the discovered names (psakefile behaviour), keeping
    all comments elsewhere in the manifest.

    .PARAMETER ManifestPath
    The .psd1 to edit.

    .PARAMETER SourcePath
    Files or directories to scan for functions and aliases.

    .PARAMETER FunctionName
    Function names to add in addition to (or instead of) a scan.

    .PARAMETER AliasName
    Alias names to add in addition to (or instead of) a scan.

    .PARAMETER Region
    Marker name for region mode, e.g. the API name.

    .PARAMETER Full
    Replace the whole arrays instead of one region.

    .PARAMETER PassThru
    Return what changed.

    .EXAMPLE
    Update-ModuleManifestExport -ManifestPath ./MyMod/MyMod.psd1 -SourcePath ./MyMod/Source/Kokoro -Region Kokoro

    .EXAMPLE
    Update-ModuleManifestExport -ManifestPath ./MyMod/MyMod.psd1 -SourcePath ./MyMod/Source -Full -WhatIf

    .OUTPUTS
    PSCustomObject (with -PassThru): ManifestPath, Function, Alias, AddedFunction, RemovedFunction.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Region')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ManifestPath,

        [Parameter()]
        [string[]]$SourcePath,

        [Parameter()]
        [string[]]$FunctionName = @(),

        [Parameter()]
        [string[]]$AliasName = @(),

        [Parameter(Mandatory, ParameterSetName = 'Region')]
        [ValidatePattern('^[\w\-\. ]+$')]
        [string]$Region,

        [Parameter(Mandatory, ParameterSetName = 'Full')]
        [switch]$Full,

        [Parameter()]
        [switch]$PassThru
    )

    $manifest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ManifestPath)
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf))
    {
        throw "Manifest not found: $manifest"
    }

    $functions = @($FunctionName)
    $aliases = @($AliasName)
    if ($SourcePath)
    {
        $found = Get-ModuleSourceExport -Path $SourcePath
        $functions += $found.Function
        $aliases += $found.Alias
    }
    $functions = @($functions | Where-Object { $_ } | Sort-Object -Unique)
    $aliases = @($aliases | Where-Object { $_ } | Sort-Object -Unique)
    if ($functions.Count -eq 0 -and $aliases.Count -eq 0 -and -not $Region)
    {
        throw 'Nothing to export: pass -FunctionName/-AliasName or a -SourcePath containing functions.'
    }

    $bytes = [System.IO.File]::ReadAllBytes($manifest)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $original = [System.Text.UTF8Encoding]::new($false).GetString($bytes).TrimStart([char]0xFEFF)

    $before = Import-PowerShellDataFile -LiteralPath $manifest
    $regionArgs = if ($PSCmdlet.ParameterSetName -eq 'Region') { @{ Region = $Region } } else { @{} }

    $updated = Set-ManifestExportArray -Text $original -Key FunctionsToExport -Name $functions @regionArgs
    $updated = Set-ManifestExportArray -Text $updated -Key AliasesToExport -Name $aliases @regionArgs

    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($updated, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0)
    {
        throw "Refusing to write a manifest that does not parse: $($errors[0].Message)"
    }

    $changed = $updated -cne $original
    if ($changed -and $PSCmdlet.ShouldProcess($manifest, 'Update FunctionsToExport/AliasesToExport'))
    {
        [System.IO.File]::WriteAllText($manifest, $updated, [System.Text.UTF8Encoding]::new($hasBom))
        try
        {
            $null = Import-PowerShellDataFile -LiteralPath $manifest -ErrorAction Stop
            # Modules whose .psm1 is produced by a build step (psake bundles source/*.ps1) have no RootModule yet;
            # Test-ModuleManifest would reject them for a reason unrelated to this edit.
            $root = (Import-PowerShellDataFile -LiteralPath $manifest).RootModule
            if ($root -and (Test-Path -LiteralPath (Join-Path -Path (Split-Path -Path $manifest -Parent) -ChildPath $root)))
            {
                $null = Test-ModuleManifest -Path $manifest -ErrorAction Stop -WarningAction SilentlyContinue
            } else
            {
                Write-Verbose "Skipping Test-ModuleManifest: RootModule '$root' is not built yet."
            }
        } catch
        {
            [System.IO.File]::WriteAllText($manifest, $original, [System.Text.UTF8Encoding]::new($hasBom))
            throw "The updated manifest is not valid and was reverted: $($_.Exception.Message)"
        }
    }

    if ($PassThru)
    {
        $previous = @($before.FunctionsToExport)
        [pscustomobject]@{
            ManifestPath    = $manifest
            Function        = $functions
            Alias           = $aliases
            AddedFunction   = @($functions | Where-Object { $_ -notin $previous })
            RemovedFunction = if ($PSCmdlet.ParameterSetName -eq 'Full') { @($previous | Where-Object { $_ -notin $functions }) } else { @() }
            Changed         = $changed
        }
    }
}
