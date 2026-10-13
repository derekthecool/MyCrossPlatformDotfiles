# Spec loading and schema interpretation for New-OpenApiClient.
# Documents are plain ordered hashtables (ConvertFrom-Json -AsHashtable), so keys such as '$ref' need no escaping.

function Import-OpenApiDocument
{
    <#
    .SYNOPSIS
    Loads an OpenAPI 3.x / Swagger 2.0 document from a file or URL and normalises it to the 3.x shape.

    .OUTPUTS
    PSCustomObject with Document (hashtable), Sha256 (of the raw bytes) and SourceName (leaf name only).
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'Uri')]
        [uri]$Uri
    )

    if ($PSCmdlet.ParameterSetName -eq 'Path')
    {
        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf))
        {
            throw "OpenAPI document not found: $resolved"
        }
        $bytes = [System.IO.File]::ReadAllBytes($resolved)
        $text = [System.Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
        $sourceName = Split-Path -Path $resolved -Leaf
    } else
    {
        $response = Invoke-WebRequest -Uri $Uri -ErrorAction Stop
        $text = if ($response.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($response.Content) } else { [string]$response.Content }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        $sourceName = $Uri.Segments[-1]
        if (-not $sourceName -or $sourceName -eq '/')
        {
            $sourceName = $Uri.Host
        }
    }

    $sha = [System.Security.Cryptography.SHA256]::HashData($bytes)
    $hash = [System.BitConverter]::ToString($sha).Replace('-', '').ToLowerInvariant()

    $trimmed = $text.TrimStart()
    if ($trimmed.StartsWith('{'))
    {
        try
        {
            $document = $text | ConvertFrom-Json -AsHashtable -Depth 100 -ErrorAction Stop
        } catch
        {
            throw "Could not parse $sourceName as JSON: $($_.Exception.Message)"
        }
    } else
    {
        if (-not (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue))
        {
            throw "$sourceName is not JSON and ConvertFrom-Yaml is not available. Install the powershell-yaml module or supply a JSON document."
        }
        $document = $text | ConvertFrom-Yaml -Ordered
    }

    if ($document.Contains('swagger') -and "$($document['swagger'])" -like '2.*')
    {
        $document = ConvertFrom-OpenApiV2Document -Document $document
    } elseif (-not $document.Contains('openapi'))
    {
        throw "$sourceName has neither an 'openapi' nor a 'swagger' version field."
    } elseif ("$($document['openapi'])" -notmatch '^3\.')
    {
        throw "Unsupported OpenAPI version '$($document['openapi'])'. Supported: 3.0.x, 3.1.x and Swagger 2.0."
    }

    [pscustomobject]@{
        Document   = $document
        Sha256     = $hash
        SourceName = $sourceName
    }
}

function ConvertFrom-OpenApiV2Document
{
    <#
    .SYNOPSIS
    Best-effort conversion of a Swagger 2.0 document to the OpenAPI 3.0 structure the generator understands.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document
    )

    # Rewrite reference targets through a JSON round-trip so every nested $ref is covered.
    $json = ConvertTo-Json -InputObject $Document -Depth 100 -Compress
    $json = $json.Replace('"#/definitions/', '"#/components/schemas/').Replace('"#/parameters/', '"#/components/parameters/')
    $source = $json | ConvertFrom-Json -AsHashtable -Depth 100

    $v3 = [ordered]@{
        openapi    = '3.0.3'
        info       = $source['info']
        servers    = @()
        paths      = [ordered]@{}
        components = [ordered]@{
            schemas         = if ($source['definitions']) { $source['definitions'] } else { [ordered]@{} }
            securitySchemes = [ordered]@{}
            parameters      = if ($source['parameters']) { $source['parameters'] } else { [ordered]@{} }
        }
    }

    $basePath = if ($source['basePath']) { [string]$source['basePath'] } else { '' }
    if ($source['host'])
    {
        $scheme = if ($source['schemes']) { @($source['schemes'])[0] } else { 'https' }
        $v3['servers'] = @(@{ url = '{0}://{1}{2}' -f $scheme, $source['host'], $basePath.TrimEnd('/') })
    } elseif ($basePath)
    {
        $v3['servers'] = @(@{ url = $basePath })
    }

    foreach ($name in @($source['securityDefinitions'].Keys))
    {
        $definition = $source['securityDefinitions'][$name]
        $v3['components']['securitySchemes'][$name] = switch ($definition['type'])
        {
            'basic' { @{ type = 'http'; scheme = 'basic' } }
            'apiKey' { @{ type = 'apiKey'; in = $definition['in']; name = $definition['name'] } }
            default { @{ type = 'oauth2'; flows = @{} } }
        }
    }
    if ($source['security'])
    {
        $v3['security'] = $source['security']
    }

    $schemaKeys = 'type', 'format', 'items', 'enum', 'default', 'minimum', 'maximum', 'minLength', 'maxLength', 'pattern', 'minItems', 'maxItems'
    $methods = 'get', 'put', 'post', 'delete', 'options', 'head', 'patch'

    foreach ($path in $source['paths'].Keys)
    {
        $pathItem = $source['paths'][$path]
        $newItem = [ordered]@{}
        foreach ($method in $methods)
        {
            if (-not $pathItem.Contains($method))
            {
                continue
            }
            $operation = $pathItem[$method]
            $newOperation = [ordered]@{}
            foreach ($key in 'summary', 'description', 'operationId', 'tags', 'deprecated', 'security')
            {
                if ($operation.Contains($key))
                {
                    $newOperation[$key] = $operation[$key]
                }
            }

            $consumes = if ($operation['consumes']) { @($operation['consumes']) } elseif ($source['consumes']) { @($source['consumes']) } else { @('application/json') }
            $produces = if ($operation['produces']) { @($operation['produces']) } elseif ($source['produces']) { @($source['produces']) } else { @('application/json') }

            $parameters = [System.Collections.Generic.List[object]]::new()
            $formProperties = [ordered]@{}
            $formRequired = [System.Collections.Generic.List[string]]::new()
            $hasFile = $false

            $allParameters = @(@($pathItem['parameters']) + @($operation['parameters'])) | Where-Object { $_ }
            foreach ($parameter in $allParameters)
            {
                if ($parameter.Contains('$ref'))
                {
                    $parameter = Resolve-OpenApiReference -Document $v3 -Reference $parameter['$ref']
                }
                switch ($parameter['in'])
                {
                    'body'
                    {
                        $content = [ordered]@{}
                        foreach ($type in $consumes)
                        {
                            $content[$type] = @{ schema = $parameter['schema'] }
                        }
                        $newOperation['requestBody'] = @{ required = [bool]$parameter['required']; content = $content }
                    }
                    'formData'
                    {
                        $schema = [ordered]@{}
                        foreach ($key in $schemaKeys)
                        {
                            if ($parameter.Contains($key))
                            {
                                $schema[$key] = $parameter[$key]
                            }
                        }
                        if ($schema['type'] -eq 'file')
                        {
                            $schema['type'] = 'string'
                            $schema['format'] = 'binary'
                            $hasFile = $true
                        }
                        if ($parameter['description'])
                        {
                            $schema['description'] = $parameter['description']
                        }
                        $formProperties[$parameter['name']] = $schema
                        if ($parameter['required'])
                        {
                            $formRequired.Add($parameter['name'])
                        }
                    }
                    default
                    {
                        $schema = [ordered]@{}
                        foreach ($key in $schemaKeys)
                        {
                            if ($parameter.Contains($key))
                            {
                                $schema[$key] = $parameter[$key]
                            }
                        }
                        $converted = [ordered]@{ name = $parameter['name']; in = $parameter['in']; required = [bool]$parameter['required']; schema = $schema }
                        if ($parameter['description'])
                        {
                            $converted['description'] = $parameter['description']
                        }
                        $parameters.Add($converted)
                    }
                }
            }
            if ($formProperties.Count -gt 0)
            {
                $formType = if ($hasFile) { 'multipart/form-data' } else { 'application/x-www-form-urlencoded' }
                $newOperation['requestBody'] = @{
                    required = ($formRequired.Count -gt 0)
                    content  = @{ $formType = @{ schema = @{ type = 'object'; properties = $formProperties; required = $formRequired.ToArray() } } }
                }
            }
            if ($parameters.Count -gt 0)
            {
                $newOperation['parameters'] = $parameters.ToArray()
            }

            $responses = [ordered]@{}
            foreach ($code in $operation['responses'].Keys)
            {
                $response = $operation['responses'][$code]
                $newResponse = [ordered]@{ description = [string]$response['description'] }
                if ($response['schema'])
                {
                    $content = [ordered]@{}
                    foreach ($type in $produces)
                    {
                        $content[$type] = @{ schema = $response['schema'] }
                    }
                    $newResponse['content'] = $content
                }
                $responses[[string]$code] = $newResponse
            }
            $newOperation['responses'] = $responses
            $newItem[$method] = $newOperation
        }
        $v3['paths'][$path] = $newItem
    }

    $v3
}

function Resolve-OpenApiReference
{
    <#
    .SYNOPSIS
    Resolves a local '#/a/b/c' JSON pointer inside the document.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document,

        [Parameter(Mandatory)]
        [string]$Reference
    )

    if (-not $Reference.StartsWith('#/'))
    {
        throw "Only local references are supported; cannot resolve '$Reference'."
    }

    $node = $Document
    foreach ($segment in $Reference.Substring(2).Split('/'))
    {
        $key = [uri]::UnescapeDataString($segment).Replace('~1', '/').Replace('~0', '~')
        if ($node -is [System.Collections.IDictionary] -and $node.Contains($key))
        {
            $node = $node[$key]
        } else
        {
            throw "Reference '$Reference' could not be resolved (missing '$key')."
        }
    }
    $node
}

function Resolve-OpenApiObject
{
    <#
    .SYNOPSIS
    Follows a chain of $ref entries (parameters, request bodies, responses) to the target object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document,

        [Parameter()]
        [AllowNull()]
        [object]$Object
    )

    $guard = 0
    while ($Object -is [System.Collections.IDictionary] -and $Object.Contains('$ref') -and $guard++ -lt 20)
    {
        $Object = Resolve-OpenApiReference -Document $Document -Reference $Object['$ref']
    }
    $Object
}

function Get-OpenApiOperation
{
    <#
    .SYNOPSIS
    Lists every operation (sorted by path then method) with path-level parameters merged in.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document
    )

    $methods = 'get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace'
    foreach ($path in @($Document['paths'].Keys | Sort-Object))
    {
        $pathItem = Resolve-OpenApiObject -Document $Document -Object $Document['paths'][$path]
        foreach ($method in $methods)
        {
            if (-not $pathItem.Contains($method))
            {
                continue
            }
            $operation = $pathItem[$method]

            # Operation-level parameters override path-level ones with the same name+location.
            $merged = [ordered]@{}
            foreach ($source in @($pathItem['parameters']), @($operation['parameters']))
            {
                foreach ($parameter in @($source))
                {
                    $parameter = Resolve-OpenApiObject -Document $Document -Object $parameter
                    if ($parameter)
                    {
                        $merged["$($parameter['in'])|$($parameter['name'])"] = $parameter
                    }
                }
            }

            [pscustomobject]@{
                Path       = $path
                Method     = $method.ToUpperInvariant()
                Operation  = $operation
                Parameters = @($merged.Values)
            }
        }
    }
}

function Get-OpenApiTypeInfo
{
    <#
    .SYNOPSIS
    Interprets a schema (following $ref/allOf/anyOf/oneOf, 3.0 nullable and 3.1 type arrays) into a flat type model.

    .DESCRIPTION
    Kind is one of: string, integer, number, boolean, array, object, file, any.
    Description/Default/Title come from the outermost schema that defines them, because
    FastAPI-style documents put them on the anyOf wrapper rather than the member.
    RefName is the first #/components/schemas name met on the way. Alternatives lists
    the non-null members of a multi-type anyOf so callers can find referenced object types.

    .OUTPUTS
    PSCustomObject type model.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document,

        [Parameter()]
        [AllowNull()]
        [object]$Schema,

        [Parameter()]
        [string[]]$Trail = @()
    )

    $info = [ordered]@{
        Kind                 = 'any'
        Nullable             = $false
        RefName              = $null
        Title                = $null
        Description          = $null
        HasDefault           = $false
        Default              = $null
        Enum                 = $null
        Format               = $null
        Minimum              = $null
        Maximum              = $null
        MinLength            = $null
        MaxLength            = $null
        Pattern              = $null
        MinItems             = $null
        MaxItems             = $null
        Items                = $null
        ScalarOrArray        = $false
        Properties           = [ordered]@{}
        Required             = @()
        AdditionalProperties = $null
        Alternatives         = @()
    }

    if ($Schema -isnot [System.Collections.IDictionary] -or $Schema.Count -eq 0)
    {
        return [pscustomobject]$info
    }

    # --- peel $ref layers ---------------------------------------------------
    $layers = [System.Collections.Generic.List[object]]::new()
    $layers.Add($Schema)
    $current = $Schema
    $guard = 0
    while ($current.Contains('$ref') -and $guard++ -lt 20)
    {
        $reference = [string]$current['$ref']
        if (-not $info.RefName)
        {
            $info.RefName = ($reference -split '/')[-1]
        }
        if ($Trail -contains $reference)
        {
            # Recursive schema: stop here so callers get an opaque object instead of looping.
            $info.Kind = 'object'
            return [pscustomobject]$info
        }
        $Trail += $reference
        $current = Resolve-OpenApiReference -Document $Document -Reference $reference
        $layers.Add($current)
    }

    $first = {
        param([string]$Key)
        foreach ($layer in $layers)
        {
            if ($layer -is [System.Collections.IDictionary] -and $layer.Contains($Key))
            {
                return @{ Value = $layer[$Key] }
            }
        }
        return $null
    }

    $titleValue = & $first 'title'
    if ($titleValue)
    {
        $info.Title = [string]$titleValue.Value
    }
    $descriptionValue = & $first 'description'
    if ($descriptionValue)
    {
        $info.Description = [string]$descriptionValue.Value
    }
    foreach ($layer in $layers)
    {
        if ($layer.Contains('default'))
        {
            $info.HasDefault = $true
            $info.Default = $layer['default']
            break
        }
    }
    foreach ($layer in $layers)
    {
        if ($layer['nullable'] -eq $true)
        {
            $info.Nullable = $true
        }
    }

    # --- composition ---------------------------------------------------------
    $inner = $current
    foreach ($combiner in 'anyOf', 'oneOf')
    {
        if (-not $inner.Contains($combiner))
        {
            continue
        }
        $members = foreach ($member in @($inner[$combiner]))
        {
            $memberType = $member['type']
            if ($memberType -eq 'null' -or ($memberType -is [System.Collections.IEnumerable] -and $memberType -isnot [string] -and @($memberType).Count -eq 1 -and @($memberType)[0] -eq 'null'))
            {
                $info.Nullable = $true
                continue
            }
            Get-OpenApiTypeInfo -Document $Document -Schema $member -Trail $Trail
        }
        $members = @($members)

        if ($members.Count -eq 1)
        {
            $merged = $members[0]
            foreach ($name in $merged.PSObject.Properties.Name)
            {
                if ($name -in 'Title', 'Description', 'HasDefault', 'Default', 'Nullable')
                {
                    continue
                }
                if ($name -eq 'RefName' -and $info.RefName)
                {
                    continue
                }
                $info[$name] = $merged.$name
            }
            if (-not $info.Description -and $merged.Description)
            {
                $info.Description = $merged.Description
            }
            if (-not $info.HasDefault -and $merged.HasDefault)
            {
                $info.HasDefault = $true
                $info.Default = $merged.Default
            }
            $info.Nullable = $info.Nullable -or $merged.Nullable
            return [pscustomobject]$info
        }

        if ($members.Count -gt 1)
        {
            $info.Alternatives = $members
            $kinds = @($members.Kind | Sort-Object -Unique)
            if ($kinds.Count -eq 1 -and $kinds[0] -notin 'object', 'any')
            {
                $info.Kind = $kinds[0]
                $info.Format = $members[0].Format
                $info.Items = $members[0].Items
            } elseif ($kinds.Count -eq 2 -and 'array' -in $kinds -and ($members | Where-Object Kind -NE 'array' | Select-Object -First 1).Kind -in 'string', 'integer', 'number')
            {
                $arrayMember = $members | Where-Object Kind -EQ 'array' | Select-Object -First 1
                $info.Kind = 'array'
                $info.Items = $arrayMember.Items
                $info.ScalarOrArray = $true
            } else
            {
                $info.Kind = 'any'
            }
            return [pscustomobject]$info
        }
        return [pscustomobject]$info
    }

    if ($inner.Contains('allOf'))
    {
        $info.Kind = 'object'
        foreach ($part in @($inner['allOf']))
        {
            $partInfo = Get-OpenApiTypeInfo -Document $Document -Schema $part -Trail $Trail
            foreach ($propertyName in $partInfo.Properties.Keys)
            {
                $info.Properties[$propertyName] = $partInfo.Properties[$propertyName]
            }
            $info.Required = @($info.Required) + @($partInfo.Required) | Select-Object -Unique
            if (-not $info.Description -and $partInfo.Description)
            {
                $info.Description = $partInfo.Description
            }
        }
    }

    # --- scalar facets ---------------------------------------------------------
    $typeWrapper = & $first 'type'
    $typeNames = @(if ($typeWrapper) { $typeWrapper.Value })
    if ('null' -in $typeNames)
    {
        $info.Nullable = $true
        $typeNames = @($typeNames | Where-Object { $_ -ne 'null' })
    }

    $contentMedia = & $first 'contentMediaType'
    $formatValue = & $first 'format'
    $format = if ($formatValue) { [string]$formatValue.Value } else { $null }
    $info.Format = $format

    if ($typeNames.Count -eq 1)
    {
        $info.Kind = switch ($typeNames[0])
        {
            'string' { if ($format -eq 'binary' -or $contentMedia) { 'file' } else { 'string' } }
            'integer' { 'integer' }
            'number' { 'number' }
            'boolean' { 'boolean' }
            'array' { 'array' }
            'object' { 'object' }
            default { 'any' }
        }
    } elseif ($typeNames.Count -eq 0 -and $info.Kind -eq 'any')
    {
        if ($inner.Contains('properties'))
        {
            $info.Kind = 'object'
        } elseif ($inner.Contains('items'))
        {
            $info.Kind = 'array'
        } elseif ($inner.Contains('enum'))
        {
            $info.Kind = 'string'
        }
    }

    foreach ($facet in 'Enum', 'Minimum', 'Maximum', 'MinLength', 'MaxLength', 'Pattern', 'MinItems', 'MaxItems')
    {
        $key = $facet.Substring(0, 1).ToLowerInvariant() + $facet.Substring(1)
        $value = & $first $key
        if ($null -ne $value)
        {
            $info[$facet] = $value.Value
        }
    }

    if ($info.Kind -eq 'array')
    {
        $itemsSchema = & $first 'items'
        if ($itemsSchema)
        {
            $info.Items = Get-OpenApiTypeInfo -Document $Document -Schema $itemsSchema.Value -Trail $Trail
        }
    }

    if ($inner.Contains('properties') -or $info.Kind -eq 'object')
    {
        if ($info.Kind -eq 'any')
        {
            $info.Kind = 'object'
        }
        if ($inner.Contains('properties'))
        {
            foreach ($propertyName in $inner['properties'].Keys)
            {
                $info.Properties[$propertyName] = Get-OpenApiTypeInfo -Document $Document -Schema $inner['properties'][$propertyName] -Trail $Trail
            }
        }
        if ($inner.Contains('required'))
        {
            $info.Required = @($info.Required) + @($inner['required']) | Select-Object -Unique
        }
        if ($inner['additionalProperties'] -is [System.Collections.IDictionary])
        {
            $info.AdditionalProperties = Get-OpenApiTypeInfo -Document $Document -Schema $inner['additionalProperties'] -Trail $Trail
        }
    }

    [pscustomobject]$info
}
