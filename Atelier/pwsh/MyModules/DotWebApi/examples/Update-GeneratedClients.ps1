#requires -Version 7.0
<#
.SYNOPSIS
Regenerates the API clients committed under Source/ from the specs listed in GeneratedClients.psd1.

.DESCRIPTION
Each client is written with New-OpenApiClient and its commands are listed in DotWebApi.psd1 (inside a
'# BEGIN generated: <Name>' block). YAML specs need the powershell-yaml module.

.PARAMETER Name
Client names to regenerate (wildcards allowed). Default: all of them.

.PARAMETER Check
Writes nothing. Generates each client into a temporary folder and fails when the committed file differs,
which is what the drift tests do.

.EXAMPLE
./Update-GeneratedClients.ps1

.EXAMPLE
./Update-GeneratedClients.ps1 -Name Frigate, OpenMeteo*

.EXAMPLE
./Update-GeneratedClients.ps1 -Check
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$Name = '*',

    [Parameter()]
    [switch]$Check
)

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
$definitions = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot 'GeneratedClients.psd1')

$selected = @($definitions.Keys | Sort-Object | Where-Object { $key = $_; $Name | Where-Object { $key -like $_ } })
if ($selected.Count -eq 0)
{
    throw "No client in GeneratedClients.psd1 matches: $($Name -join ', ')"
}

$drifted = [System.Collections.Generic.List[string]]::new()
foreach ($client in $selected)
{
    $definition = $definitions[$client]
    $arguments = @{
        Path       = Join-Path $moduleRoot $definition.Path
        Name       = $client
        OutputPath = Join-Path $moduleRoot $definition.OutputPath
    }
    if ($definition.DefaultEndpoint)
    {
        $arguments.DefaultEndpoint = $definition.DefaultEndpoint
    }
    if ($definition.NameOverride)
    {
        $arguments.NameOverride = $definition.NameOverride
    }

    if ($Check)
    {
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) "generated-$client-$([guid]::NewGuid().ToString('N'))"
        try
        {
            $arguments.OutputPath = $temp
            $null = New-OpenApiClient @arguments -RuntimeMode Module -PassThru 6>$null
            $fresh = (Get-Content -LiteralPath (Join-Path $temp "$client.ps1") -Raw) -replace "`r`n", "`n"
            $committed = (Get-Content -LiteralPath (Join-Path (Join-Path $moduleRoot $definition.OutputPath) "$client.ps1") -Raw) -replace "`r`n", "`n"
            if ($fresh -ne $committed)
            {
                $drifted.Add($client)
                Write-Warning "$client differs from what the generator produces."
            } else
            {
                Write-Information "$client is up to date." -InformationAction Continue
            }
        } finally
        {
            Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else
    {
        $null = New-OpenApiClient @arguments -ManifestPath (Join-Path $moduleRoot 'DotWebApi.psd1') -UpdateManifest -PassThru
    }
}

if ($drifted.Count -gt 0)
{
    throw "Out of date: $($drifted -join ', '). Run examples/Update-GeneratedClients.ps1 and commit the result."
}
