$Script:OpenApiGeneratorVersion = '1.0.0'

function Get-OpenApiClientName
{
    <#
    .SYNOPSIS
    Derives a PascalCase client name from an API title ('Kokoro TTS API' -> 'Kokoro').
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Title,

        [Parameter()]
        [string]$Fallback = 'Api'
    )

    $noise = 'api', 'apis', 'rest', 'restful', 'service', 'services', 'web', 'swagger', 'openapi', 'specification', 'spec', 'endpoint', 'endpoints', 'public'
    $words = @(Split-OpenApiWord -Text $Title | Where-Object { $_.ToLowerInvariant() -notin $noise })
    # Trailing short acronyms ('TTS') are usually a category, not part of the name.
    while ($words.Count -gt 1 -and $words[-1] -cmatch '^[A-Z]{2,4}$')
    {
        $words = @($words | Select-Object -SkipLast 1)
    }
    $name = ConvertTo-OpenApiPascalCase -Word $words
    if (-not $name -or $name -match '^\d')
    {
        $name = $Fallback
    }
    $name
}

function Get-OpenApiServerInfo
{
    <#
    .SYNOPSIS
    Returns the first server URL (variables replaced by their defaults) split into ServerUrl and BasePath.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document
    )

    $result = [pscustomobject]@{ ServerUrl = $null; BasePath = '' }
    $server = @($Document['servers']) | Where-Object { $_ } | Select-Object -First 1
    if (-not $server -or -not $server['url'])
    {
        return $result
    }

    $url = [string]$server['url']
    if ($server['variables'])
    {
        foreach ($variable in $server['variables'].Keys)
        {
            $url = $url.Replace("{$variable}", [string]$server['variables'][$variable]['default'])
        }
    }

    if ($url -match '^https?://')
    {
        $result.ServerUrl = $url.TrimEnd('/')
        $path = ([uri]$url).AbsolutePath.TrimEnd('/')
        $result.BasePath = if ($path -eq '/') { '' } else { $path }
    } elseif ($url.StartsWith('/'))
    {
        $result.BasePath = $url.TrimEnd('/')
    }
    $result
}

function ConvertTo-OpenApiClientInfoSource
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document,

        [Parameter(Mandatory)]
        [string]$ClientVariable,

        [Parameter(Mandatory)]
        [string]$Prefix,

        [Parameter()]
        [string]$DefaultEndpoint
    )

    $server = Get-OpenApiServerInfo -Document $Document
    $schemes = foreach ($scheme in @($Document['components']['securitySchemes'].Values) | Where-Object { $_ })
    {
        $parts = [System.Collections.Generic.List[string]]::new()
        $parts.Add("Type = $(ConvertTo-OpenApiLiteral -Value ([string]$scheme['type']))")
        if ($scheme['scheme'])
        {
            $parts.Add("Scheme = $(ConvertTo-OpenApiLiteral -Value ([string]$scheme['scheme']))")
        }
        if ($scheme['in'])
        {
            $parts.Add("In = $(ConvertTo-OpenApiLiteral -Value ([string]$scheme['in']))")
        }
        if ($scheme['name'])
        {
            $parts.Add("Name = $(ConvertTo-OpenApiLiteral -Value ([string]$scheme['name']))")
        }
        "        @{ $($parts -join '; ') }"
    }
    $schemes = @($schemes)

    $title = [string]$Document['info']['title']
    $version = [string]$Document['info']['version']
    $endpoint = if ($DefaultEndpoint) { ConvertTo-OpenApiLiteral -Value $DefaultEndpoint.TrimEnd('/') } else { '$null' }
    $serverUrl = if ($server.ServerUrl) { ConvertTo-OpenApiLiteral -Value $server.ServerUrl } else { '$null' }

    $lines = @(
        "`$Script:$ClientVariable = @{"
        "    ApiName         = $(ConvertTo-OpenApiLiteral -Value $Prefix)"
        "    Title           = $(ConvertTo-OpenApiLiteral -Value $title)"
        "    Version         = $(ConvertTo-OpenApiLiteral -Value $version)"
        "    DefaultEndpoint = $endpoint"
        "    ServerUrl       = $serverUrl"
        "    BasePath        = $(ConvertTo-OpenApiLiteral -Value $server.BasePath)"
    )
    if ($schemes.Count -gt 0)
    {
        $lines += '    SecuritySchemes = @('
        $lines += $schemes
        $lines += '    )'
    } else
    {
        $lines += '    SecuritySchemes = @()'
    }
    $lines += '}'
    $lines -join "`n"
}

function Write-OpenApiGeneratedFile
{
    <#
    .SYNOPSIS
    Writes UTF-8 (no BOM, LF) text only when it differs; refuses to overwrite hand-written files without -Force.

    .OUTPUTS
    'Created', 'Updated' or 'Unchanged'.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter()]
        [switch]$Force
    )

    $text = ($Content -replace "`r`n", "`n").TrimEnd() + "`n"
    $state = 'Created'
    if (Test-Path -LiteralPath $Path -PathType Leaf)
    {
        $existing = [System.IO.File]::ReadAllText($Path)
        if ($existing -ceq $text)
        {
            return 'Unchanged'
        }
        if (-not $Force -and $existing -notmatch '# <auto-generated>')
        {
            throw "$Path exists and was not generated by New-OpenApiClient. Use -Force to overwrite it."
        }
        $state = 'Updated'
    }

    if ($PSCmdlet.ShouldProcess($Path, "$state generated file"))
    {
        $directory = Split-Path -Path $Path -Parent
        if ($directory -and -not (Test-Path -LiteralPath $directory))
        {
            $null = New-Item -ItemType Directory -Path $directory -Force
        }
        [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
    }
    $state
}

function New-OpenApiClient
{
    <#
    .SYNOPSIS
    Generates a PowerShell function library (one .ps1) from an OpenAPI 3.x / Swagger 2.0 document.

    .DESCRIPTION
    Reads the API description and writes a deterministic, committed script containing:
    - one function per operation, named Verb-<Prefix>Noun from the HTTP method and summary/operationId
      (approved verbs only); path, query and header values and the top-level properties of the request
      body become typed, validated parameters with comment-based help;
    - pipeline input: parameters bind by property name, and body operations also accept a hashtable/object
      (or a plain string for the single required text property) through -InputObject;
    - New-<Prefix><Type> constructors for named object schemas used in requests (PSTypeName-tagged);
    - Get/Set/Clear-<Prefix>DefaultEndpoint and Set-<Prefix>Credential, with -Endpoint and -Credential
      on every function. Endpoint order: -Endpoint, <PREFIX>_ENDPOINT, saved setting, -DefaultEndpoint, spec server.

    Responses are interpreted by their real Content-Type: JSON is parsed, other content is saved to
    -OutFile (or a temp file) and returned as a FileInfo.

    The functions call a shared request runtime. -RuntimeMode Module uses DotWebApi's own; Embedded
    writes a private copy next to the client so the output works in any other module. The output
    directory and manifest can be anywhere.

    .PARAMETER Path
    OpenAPI/Swagger JSON file (YAML too when ConvertFrom-Yaml is available).

    .PARAMETER Uri
    URL of an API description.

    .PARAMETER Name
    Client name, used for the output file name. Defaults to a cleaned-up info.title.

    .PARAMETER Prefix
    Noun prefix for generated functions (-Prefix Nice gives Get-NiceObject). Use it to keep two APIs that both
    have a plain Get-Object apart, or to keep generated names clear of an older module. Defaults to -Name.

    .PARAMETER OutputPath
    Directory (file becomes <Name>.ps1) or an explicit .ps1 path, anywhere. Default: Source/<Name> of the
    DotWebApi module, or the current directory when the generator is not running from the module.

    .PARAMETER ManifestPath
    Module manifest (.psd1) to update with -UpdateManifest. Defaults to the nearest .psd1 above the output.

    .PARAMETER RuntimeMode
    Auto (default): Module when the output is inside DotWebApi, otherwise Embedded.

    .PARAMETER RuntimeName
    Embedded runtime only: name stem of the copied runtime (functions become Invoke-<RuntimeName>ApiRequest, file
    private/<RuntimeName>.Runtime.ps1). Defaults to -Prefix. Give every client in one module the same value
    (for example the module's own name) and they share a single runtime file instead of one copy each.

    .PARAMETER ReservedName
    Command names that must not be generated, for example the exports of an older module you want to keep loading
    next to the new one. Clashing operation and type-constructor names are renamed; a clash with a helper command
    (Get/Set/Clear-<Prefix>DefaultEndpoint, Set-<Prefix>Credential) is an error, so pick another -Prefix.

    .PARAMETER RawPathParameter
    Path parameters whose '/' characters must be kept in the URL (catch-all routes). A trailing parameter named
    path, filepath, catchall, rest, wildcard or remainder is treated this way automatically.

    .PARAMETER DefaultEndpoint
    Endpoint baked into the client, e.g. http://192.168.1.103:8880.

    .PARAMETER IncludePath
    Only operations whose path matches one of these wildcards.

    .PARAMETER ExcludePath
    Skip operations whose path matches one of these wildcards.

    .PARAMETER Tag
    Only operations tagged with one of these (wildcards allowed).

    .PARAMETER VerbMap
    Extra word-to-verb mappings, e.g. @{ phonemize = 'ConvertTo' }.

    .PARAMETER NameOverride
    Function names keyed by operationId or 'METHOD /path', e.g. @{ 'POST /dev/phonemize' = 'ConvertTo-KokoroPhoneme' }.

    .PARAMETER IncludeDeprecated
    Also generate operations marked deprecated.

    .PARAMETER UpdateManifest
    Write the generated function names into the manifest's FunctionsToExport between generated-region markers.

    .PARAMETER Force
    Overwrite an existing file that was not generated by this command.

    .PARAMETER PassThru
    Return a result object.

    .EXAMPLE
    New-OpenApiClient -Path ./kokoro_tts_openapi.json -DefaultEndpoint http://192.168.1.103:8880 -OutputPath ./Source/Kokoro -UpdateManifest

    .EXAMPLE
    New-OpenApiClient -Uri https://example.com/openapi.json -OutputPath ~/work/MyModule/Source/Example -ManifestPath ~/work/MyModule/MyModule.psd1 -UpdateManifest -RuntimeMode Embedded

    .OUTPUTS
    With -PassThru: PSCustomObject (ClientPath, RuntimePath, ManifestPath, Function, State, Renamed).
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Path')]
    [Alias('openapigen')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Path')]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'Uri')]
        [uri]$Uri,

        [Parameter()]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
        [string]$Name,

        [Parameter()]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
        [string]$Prefix,

        [Parameter()]
        [string]$OutputPath,

        [Parameter()]
        [string]$ManifestPath,

        [Parameter()]
        [ValidateSet('Auto', 'Module', 'Embedded')]
        [string]$RuntimeMode = 'Auto',

        [Parameter()]
        [ValidatePattern('^https?://')]
        [string]$DefaultEndpoint,

        [Parameter()]
        [string[]]$IncludePath,

        [Parameter()]
        [string[]]$ExcludePath,

        [Parameter()]
        [string[]]$Tag,

        [Parameter()]
        [string[]]$RawPathParameter = @(),

        [Parameter()]
        [string[]]$ReservedName = @(),

        [Parameter()]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
        [string]$RuntimeName,

        [Parameter()]
        [hashtable]$VerbMap = @{},

        [Parameter()]
        [hashtable]$NameOverride = @{},

        [Parameter()]
        [switch]$IncludeDeprecated,

        [Parameter()]
        [switch]$UpdateManifest,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )

    $loaded = if ($PSCmdlet.ParameterSetName -eq 'Uri') { Import-OpenApiDocument -Uri $Uri } else { Import-OpenApiDocument -Path $Path }
    $document = $loaded.Document
    if (-not $document['paths'] -or $document['paths'].Count -eq 0)
    {
        throw "$($loaded.SourceName) defines no paths."
    }
    if (-not $document['components'])
    {
        $document['components'] = [ordered]@{}
    }
    if (-not $document['components']['securitySchemes'])
    {
        $document['components']['securitySchemes'] = [ordered]@{}
    }

    $title = [string]$document['info']['title']
    $fallback = [System.IO.Path]::GetFileNameWithoutExtension($loaded.SourceName) -replace '[^A-Za-z0-9]', ''
    if (-not $Name)
    {
        $Name = Get-OpenApiClientName -Title $title -Fallback $(if ($fallback -match '^[A-Za-z]') { $fallback } else { 'Api' })
    }
    if (-not $Prefix)
    {
        $Prefix = $Name
    }
    if (-not $RuntimeName)
    {
        $RuntimeName = $Prefix
    }
    $clientVariable = "${Prefix}ClientInfo"

    # --- where does it go? ------------------------------------------------------
    $module = $MyInvocation.MyCommand.Module
    $moduleBase = if ($module) { [System.IO.Path]::GetFullPath($module.ModuleBase).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar } else { $null }

    if ($OutputPath)
    {
        $target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    } elseif ($moduleBase)
    {
        $target = Join-Path -Path $moduleBase -ChildPath (Join-Path 'Source' $Name)
    } else
    {
        $target = (Get-Location).ProviderPath
    }
    if ($target -like '*.ps1')
    {
        $clientPath = $target
        $outputDirectory = Split-Path -Path $target -Parent
    } else
    {
        $outputDirectory = $target
        $clientPath = Join-Path -Path $target -ChildPath "$Name.ps1"
    }

    $insideModule = $moduleBase -and ([System.IO.Path]::GetFullPath($outputDirectory).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar).StartsWith($moduleBase, [System.StringComparison]::OrdinalIgnoreCase)
    $mode = switch ($RuntimeMode)
    {
        'Auto' { if ($insideModule) { 'Module' } else { 'Embedded' } }
        default { $_ }
    }
    if ($mode -eq 'Module' -and -not $insideModule)
    {
        Write-Warning "RuntimeMode Module was requested but $outputDirectory is outside the DotWebApi module; the output only works when loaded inside DotWebApi."
    }

    # --- operations -------------------------------------------------------------
    $records = foreach ($item in Get-OpenApiOperation -Document $document)
    {
        $operation = $item.Operation
        if ($operation['deprecated'] -eq $true -and -not $IncludeDeprecated)
        {
            Write-Verbose "Skipping deprecated $($item.Method) $($item.Path)"
            continue
        }
        if ($IncludePath -and -not ($IncludePath | Where-Object { $item.Path -like $_ }))
        {
            continue
        }
        if ($ExcludePath -and ($ExcludePath | Where-Object { $item.Path -like $_ }))
        {
            continue
        }
        if ($Tag -and -not (@($operation['tags']) | Where-Object { $t = $_; $Tag | Where-Object { $t -like $_ } }))
        {
            continue
        }
        [pscustomobject]@{
            Path        = $item.Path
            Method      = $item.Method
            Operation   = $operation
            Parameters  = $item.Parameters
            Summary     = [string]$operation['summary']
            OperationId = [string]$operation['operationId']
            Name        = $null
            Verb        = $null
            Noun        = $null
        }
    }
    $records = @($records)
    if ($records.Count -eq 0)
    {
        throw 'No operations left after applying the filters.'
    }

    $configNames = @("Get-${Prefix}DefaultEndpoint", "Set-${Prefix}DefaultEndpoint", "Clear-${Prefix}DefaultEndpoint", "Set-${Prefix}Credential")
    $clashes = @($configNames | Where-Object { $_ -in $ReservedName })
    if ($clashes.Count -gt 0)
    {
        throw "The helper command(s) $($clashes -join ', ') collide with -ReservedName. Choose a different -Prefix."
    }
    $null = Resolve-OpenApiFunctionName -Operation $records -Prefix $Prefix -VerbMap $VerbMap -NameOverride $NameOverride -ReservedName ($configNames + $ReservedName)

    $models = foreach ($record in $records)
    {
        New-OpenApiOperationModel -Document $document -Record $record -ClientName $Prefix -RawPathParameter $RawPathParameter
    }
    $models = @($models | Sort-Object -Property Name)

    # --- object constructors -----------------------------------------------------
    $usedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($known in $configNames + @($models.Name) + $ReservedName)
    {
        $null = $usedNames.Add($known)
    }
    $objectTypes = [ordered]@{}
    foreach ($model in $models)
    {
        foreach ($descriptor in $model.Parameter)
        {
            foreach ($found in Find-OpenApiObjectType -TypeInfo $descriptor.TypeInfo)
            {
                if (-not $objectTypes.Contains($found.RefName))
                {
                    $objectTypes[$found.RefName] = $found
                }
            }
        }
    }
    $constructors = foreach ($refName in @($objectTypes.Keys | Sort-Object))
    {
        $words = @(Split-OpenApiWord -Text $refName)
        $words[-1] = Get-OpenApiSingularWord -Word $words[-1]
        $functionName = "New-$Prefix$(ConvertTo-OpenApiPascalCase -Word $words)"
        if (-not $usedNames.Add($functionName))
        {
            $functionName += 'Object'
            $null = $usedNames.Add($functionName)
        }
        [pscustomobject]@{ Name = $functionName; TypeName = "$Prefix.$refName"; TypeInfo = $objectTypes[$refName] }
    }
    $constructors = @($constructors)

    # --- assemble -----------------------------------------------------------------
    $header = @(
        '# <auto-generated>'
        '#   Generated code: do not edit by hand, regenerate it from the API description below.'
        "#   Source : $($loaded.SourceName) - $title $($document['info']['version'])"
        "#   SHA256 : $($loaded.Sha256)"
        "#   Runtime: $mode"
        '# </auto-generated>'
    ) -join "`n"

    $sections = [System.Collections.Generic.List[string]]::new()
    $sections.Add($header)
    $sections.Add((ConvertTo-OpenApiClientInfoSource -Document $document -ClientVariable $clientVariable -Prefix $Prefix -DefaultEndpoint $DefaultEndpoint))
    $sections.Add((ConvertTo-OpenApiConfigSource -Prefix $Prefix -ClientVariable $clientVariable))
    foreach ($constructor in $constructors)
    {
        $sections.Add((ConvertTo-OpenApiConstructorSource -FunctionName $constructor.Name -TypeName $constructor.TypeName -TypeInfo $constructor.TypeInfo))
    }
    foreach ($model in $models)
    {
        $sections.Add((ConvertTo-OpenApiFunctionSource -Model $model -ClientVariable $clientVariable -BodyTableName 'ConvertTo-OpenApiBodyTable' -RuntimeName 'Invoke-OpenApiRequest'))
    }
    $clientText = $sections -join "`n`n"

    $runtimeSource = Join-Path -Path $PSScriptRoot -ChildPath 'private/Invoke-OpenApiRequest.ps1'
    $runtimeText = $null
    if ($mode -eq 'Embedded')
    {
        $clientText = [regex]::Replace($clientText, '\b(Invoke|Get|Set|Clear|Resolve|ConvertTo)-OpenApi(?=[A-Z])', "`$1-${RuntimeName}Api")
        $runtimeText = ([System.IO.File]::ReadAllText($runtimeSource))
        # The comment block at the top of the source file is a note for the generator's developers; generated code
        # must not mention the generator, so only the neutral header below is kept.
        $runtimeText = [regex]::Replace($runtimeText, '\A(?:#[^\r\n]*\r?\n)+\r?\n', '')
        $runtimeText = $runtimeText.Replace('OpenApi', "${RuntimeName}Api")
        $runtimeText = "# <auto-generated>`n#   Shared request runtime (${RuntimeName}Api*) used by the generated API clients in this folder.`n#   Do not edit by hand; regenerate the clients instead. Every client generated with the same runtime name shares this file.`n# </auto-generated>`n`n" + $runtimeText
    }

    $publicNames = @($configNames + @($constructors.Name) + @($models.Name)) | Sort-Object
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($clientText, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0)
    {
        throw "Generated code does not parse (line $($errors[0].Extent.StartLineNumber)): $($errors[0].Message)"
    }
    $defined = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false).Name)
    $missing = @($publicNames | Where-Object { $_ -notin $defined })
    if ($missing.Count -gt 0)
    {
        throw "Generated code is missing expected functions: $($missing -join ', ')"
    }

    # --- write ----------------------------------------------------------------------
    $state = Write-OpenApiGeneratedFile -Path $clientPath -Content $clientText -Force:$Force -WhatIf:$WhatIfPreference
    $runtimePath = $null
    if ($runtimeText)
    {
        $runtimePath = Join-Path -Path (Join-Path -Path $outputDirectory -ChildPath 'private') -ChildPath "$RuntimeName.Runtime.ps1"
        $null = Write-OpenApiGeneratedFile -Path $runtimePath -Content $runtimeText -Force:$Force -WhatIf:$WhatIfPreference
    }

    $resolvedManifest = $null
    if ($UpdateManifest)
    {
        if ($ManifestPath)
        {
            $resolvedManifest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ManifestPath)
        } else
        {
            $probe = $outputDirectory
            while ($probe -and -not $resolvedManifest)
            {
                $found = @(Get-ChildItem -LiteralPath $probe -Filter '*.psd1' -File -ErrorAction SilentlyContinue)
                if ($found.Count -eq 1)
                {
                    $resolvedManifest = $found[0].FullName
                } elseif ($found.Count -gt 1)
                {
                    throw "Several manifests in $probe ($($found.Name -join ', ')); pass -ManifestPath."
                }
                $probe = Split-Path -Path $probe -Parent
            }
            if (-not $resolvedManifest)
            {
                throw "No .psd1 found at or above $outputDirectory; pass -ManifestPath."
            }
            Write-Host "Updating manifest $resolvedManifest" -ForegroundColor DarkGray
        }
        Update-ModuleManifestExport -ManifestPath $resolvedManifest -FunctionName $publicNames -Region $Name -WhatIf:$WhatIfPreference
    } else
    {
        Write-Verbose "Export these from your module manifest: $($publicNames -join ', ')"
    }

    $renamed = @($records | Where-Object { $_.Disambiguated } | ForEach-Object { $_.Name } | Sort-Object)
    Write-Host ("{0} {1}: {2} operation(s), {3} type constructor(s) ({4} runtime)" -f $state, $clientPath, $models.Count, $constructors.Count, $mode) -ForegroundColor Green
    if ($renamed.Count -gt 0)
    {
        Write-Host "Disambiguated: $($renamed -join ', ')" -ForegroundColor Yellow
    }

    if ($PassThru)
    {
        [pscustomobject]@{
            ClientPath   = $clientPath
            RuntimePath  = $runtimePath
            ManifestPath = $resolvedManifest
            RuntimeMode  = $mode
            State        = $state
            Function     = $publicNames
            Renamed      = $renamed
        }
    }
}
