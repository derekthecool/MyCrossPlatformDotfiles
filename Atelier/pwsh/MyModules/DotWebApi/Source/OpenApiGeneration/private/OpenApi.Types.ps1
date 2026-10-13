# Turns parsed operations into parameter/response models ready for code emission.

function ConvertTo-OpenApiLiteral
{
    <#
    .SYNOPSIS
    Renders a value as PowerShell source (single-quoted strings, invariant numbers).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value)
    {
        return '$null'
    }
    if ($Value -is [bool])
    {
        return $(if ($Value) { '$true' } else { '$false' })
    }
    if ($Value -is [string])
    {
        return "'" + $Value.Replace("'", "''") + "'"
    }
    if ($Value -is [double] -or $Value -is [single] -or $Value -is [decimal])
    {
        return ([double]$Value).ToString('R', [cultureinfo]::InvariantCulture)
    }
    if ($Value -is [System.ValueType])
    {
        return ([System.IFormattable]$Value).ToString($null, [cultureinfo]::InvariantCulture)
    }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [System.Collections.IDictionary])
    {
        $items = @($Value | ForEach-Object { ConvertTo-OpenApiLiteral -Value $_ })
        return '@(' + ($items -join ', ') + ')'
    }
    "'" + ([string]$Value).Replace("'", "''") + "'"
}

function Get-OpenApiPowerShellType
{
    <#
    .SYNOPSIS
    Maps a type model to a PowerShell type literal plus validation attributes.

    .PARAMETER Mandatory
    Booleans stay [bool] when mandatory; optional ones become [switch] unless the spec default is true.

    .OUTPUTS
    PSCustomObject: Type, IsSwitch, IsFile, Validate (attribute source lines).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TypeInfo,

        [Parameter()]
        [switch]$Mandatory
    )

    $validate = [System.Collections.Generic.List[string]]::new()
    $isSwitch = $false
    $isFile = $false

    $type = switch ($TypeInfo.Kind)
    {
        'string' { '[string]' }
        'integer' { if ($TypeInfo.Format -eq 'int64') { '[long]' } else { '[int]' } }
        'number' { '[double]' }
        'boolean'
        {
            if ($Mandatory -or ($TypeInfo.HasDefault -and $TypeInfo.Default -eq $true))
            {
                '[bool]'
            } else
            {
                $isSwitch = $true
                '[switch]'
            }
        }
        'array'
        {
            $itemKind = if ($TypeInfo.Items) { $TypeInfo.Items.Kind } else { 'any' }
            switch ($itemKind)
            {
                'string' { '[string[]]' }
                'integer' { '[long[]]' }
                'number' { '[double[]]' }
                'boolean' { '[bool[]]' }
                default { '[object[]]' }
            }
        }
        'file'
        {
            $isFile = $true
            $validate.Add("[ValidateScript({ Test-Path -LiteralPath `$_ -PathType Leaf })]")
            '[string]'
        }
        default { '[object]' }
    }

    $numeric = $TypeInfo.Kind -in 'integer', 'number'
    if ($TypeInfo.Enum -and $TypeInfo.Kind -in 'string', 'integer')
    {
        $validate.Add('[ValidateSet(' + ((@($TypeInfo.Enum) | ForEach-Object { ConvertTo-OpenApiLiteral -Value $_ }) -join ', ') + ')]')
    }
    if ($numeric -and ($null -ne $TypeInfo.Minimum -or $null -ne $TypeInfo.Maximum))
    {
        $upper = if ($TypeInfo.Kind -eq 'integer') { '[long]::MaxValue' } else { '[double]::MaxValue' }
        $lower = if ($TypeInfo.Kind -eq 'integer') { '[long]::MinValue' } else { '[double]::MinValue' }
        $min = if ($null -ne $TypeInfo.Minimum) { ConvertTo-OpenApiLiteral -Value $TypeInfo.Minimum } else { $lower }
        $max = if ($null -ne $TypeInfo.Maximum) { ConvertTo-OpenApiLiteral -Value $TypeInfo.Maximum } else { $upper }
        $validate.Add("[ValidateRange($min, $max)]")
    }
    if ($TypeInfo.Kind -eq 'string' -and ($null -ne $TypeInfo.MinLength -or $null -ne $TypeInfo.MaxLength))
    {
        $min = if ($null -ne $TypeInfo.MinLength) { $TypeInfo.MinLength } else { 0 }
        $max = if ($null -ne $TypeInfo.MaxLength) { $TypeInfo.MaxLength } else { '[int]::MaxValue' }
        $validate.Add("[ValidateLength($min, $max)]")
    }
    if ($TypeInfo.Kind -eq 'string' -and $TypeInfo.Pattern)
    {
        # ValidatePattern ignores case unless told otherwise; schema patterns are case-sensitive.
        $validate.Add("[ValidatePattern($(ConvertTo-OpenApiLiteral -Value $TypeInfo.Pattern), Options = 'None')]")
    }
    if ($TypeInfo.Kind -eq 'array' -and ($null -ne $TypeInfo.MinItems -or $null -ne $TypeInfo.MaxItems))
    {
        $min = if ($null -ne $TypeInfo.MinItems) { $TypeInfo.MinItems } else { 0 }
        $max = if ($null -ne $TypeInfo.MaxItems) { $TypeInfo.MaxItems } else { '[int]::MaxValue' }
        $validate.Add("[ValidateCount($min, $max)]")
    }

    [pscustomobject]@{
        Type     = $type
        IsSwitch = $isSwitch
        IsFile   = $isFile
        Validate = $validate.ToArray()
    }
}

function Find-OpenApiObjectType
{
    <#
    .SYNOPSIS
    Walks a type model (items, additionalProperties, anyOf members, nested properties) and returns named object schemas.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [pscustomobject]$TypeInfo,

        [Parameter()]
        [int]$Depth = 0
    )

    if ($null -eq $TypeInfo -or $Depth -gt 6)
    {
        return
    }
    if ($TypeInfo.RefName -and $TypeInfo.Kind -eq 'object' -and $TypeInfo.Properties.Count -gt 0)
    {
        $TypeInfo
    }
    foreach ($child in @($TypeInfo.Items) + @($TypeInfo.AdditionalProperties) + @($TypeInfo.Alternatives) + @($TypeInfo.Properties.Values))
    {
        if ($child -is [pscustomobject])
        {
            Find-OpenApiObjectType -TypeInfo $child -Depth ($Depth + 1)
        }
    }
}

function Get-OpenApiDefaultText
{
    <#
    .SYNOPSIS
    Formats a spec default for help text; returns $null when there is none worth showing.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TypeInfo
    )

    if (-not $TypeInfo.HasDefault -or $null -eq $TypeInfo.Default)
    {
        return $null
    }
    if ($TypeInfo.Default -is [System.Collections.IDictionary] -or ($TypeInfo.Default -is [System.Collections.IEnumerable] -and $TypeInfo.Default -isnot [string]))
    {
        return ConvertTo-Json -InputObject $TypeInfo.Default -Compress -Depth 5
    }
    if ($TypeInfo.Default -is [bool])
    {
        return $TypeInfo.Default.ToString().ToLowerInvariant()
    }
    [string]$TypeInfo.Default
}

function New-OpenApiParameterDescriptor
{
    <#
    .SYNOPSIS
    Builds one parameter descriptor (no final PowerShell name yet) from a wire name and type model.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Wire,

        [Parameter(Mandatory)]
        [ValidateSet('path', 'query', 'header', 'body', 'ctor')]
        [string]$In,

        [Parameter(Mandatory)]
        [pscustomobject]$TypeInfo,

        [Parameter()]
        [bool]$Mandatory,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$Style
    )

    $null = $Style
    $mapped = Get-OpenApiPowerShellType -TypeInfo $TypeInfo -Mandatory:$Mandatory
    $text = if ($Description) { $Description } elseif ($TypeInfo.Description) { $TypeInfo.Description } elseif ($TypeInfo.Title) { $TypeInfo.Title } else { $null }

    [pscustomobject]@{
        Name        = $null
        Wire        = $Wire
        In          = $In
        TypeInfo    = $TypeInfo
        Type        = $mapped.Type
        IsSwitch    = $mapped.IsSwitch
        IsFile      = $mapped.IsFile
        Validate    = $mapped.Validate
        Mandatory   = $Mandatory
        Alias       = @()
        Csv         = $false
        Default     = Get-OpenApiDefaultText -TypeInfo $TypeInfo
        Allowed     = if ($TypeInfo.Enum) { @($TypeInfo.Enum) } else { $null }
        ObjectType  = $null
        Description = $text
    }
}

function Set-OpenApiParameterName
{
    <#
    .SYNOPSIS
    Gives every descriptor a unique PowerShell name and non-conflicting aliases (wire name, Id for the last path parameter).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Descriptor,

        [Parameter()]
        [string[]]$ReservedName = @()
    )

    $used = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $Script:OpenApiReservedParameter + $ReservedName)
    {
        $null = $used.Add($name)
    }

    $locationPrefix = @{ path = 'Path'; query = 'Query'; header = 'Header'; body = 'Body'; ctor = 'Property' }
    foreach ($item in $Descriptor)
    {
        $base = ConvertTo-OpenApiParameterName -WireName $item.Wire
        $candidate = $base
        if ($used.Contains($candidate) -or $candidate -in 'InputObjectValue')
        {
            $candidate = $locationPrefix[$item.In] + $base
        }
        $index = 2
        while ($used.Contains($candidate))
        {
            $candidate = "$base$index"
            $index++
        }
        $null = $used.Add($candidate)
        $item.Name = $candidate
    }

    # An alias only has to avoid real parameter names; automatic-variable names such as 'input' are fine as aliases
    # (the value still lands in the renamed parameter), which keeps wire-name binding like -Input working.
    $blocked = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $Script:OpenApiCommonParameter + $ReservedName + @($Descriptor.Name))
    {
        $null = $blocked.Add($name)
    }

    foreach ($item in $Descriptor)
    {
        $aliases = [System.Collections.Generic.List[string]]::new()
        if ($item.Wire -match '^[A-Za-z_][A-Za-z0-9_]*$' -and $item.Wire -ine $item.Name -and $blocked.Add($item.Wire))
        {
            $aliases.Add($item.Wire)
        }
        if ($item.IsFile)
        {
            foreach ($fileAlias in 'FullName', 'Path')
            {
                if ($blocked.Add($fileAlias))
                {
                    $aliases.Add($fileAlias)
                }
            }
        }
        $item.Alias = $aliases.ToArray()
    }

    $lastPath = $Descriptor | Where-Object In -EQ 'path' | Select-Object -Last 1
    if ($lastPath -and $lastPath.Name -ne 'Id' -and $blocked.Add('Id'))
    {
        $lastPath.Alias = @($lastPath.Alias) + 'Id'
    }
}

function Get-OpenApiResponseModel
{
    <#
    .SYNOPSIS
    Classifies the success response: none, bool (HEAD), json (typed), unknown (empty schema - sniffed at runtime), binary or text.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Operation,

        [Parameter(Mandatory)]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$ClientName
    )

    $model = [pscustomobject]@{ Kind = 'none'; TypeName = $null; OutputType = $null }
    if ($Method -eq 'HEAD')
    {
        $model.Kind = 'bool'
        $model.OutputType = '[bool]'
        return $model
    }

    $responses = $Operation['responses']
    $code = @($responses.Keys | Where-Object { "$_" -match '^2\d\d$' } | Sort-Object) | Select-Object -First 1
    if (-not $code -and $responses -and $responses.Contains('default'))
    {
        $code = 'default'
    }
    if (-not $code)
    {
        return $model
    }

    $response = Resolve-OpenApiObject -Document $Document -Object $responses[$code]
    $content = $response['content']
    if (-not $content -or $content.Count -eq 0)
    {
        return $model
    }

    $jsonKey = @($content.Keys | Where-Object { $_ -match 'json' }) | Select-Object -First 1
    if ($jsonKey)
    {
        $typeInfo = Get-OpenApiTypeInfo -Document $Document -Schema $content[$jsonKey]['schema']
        if ($typeInfo.Kind -eq 'any' -and -not $typeInfo.RefName -and $typeInfo.Alternatives.Count -eq 0)
        {
            $model.Kind = 'unknown'
            $model.OutputType = '[System.IO.FileInfo], [pscustomobject], [string]'
            return $model
        }
        $model.Kind = 'json'
        $typed = if ($typeInfo.Kind -eq 'array' -and $typeInfo.Items) { $typeInfo.Items } else { $typeInfo }
        if ($typed.RefName -and $typed.Kind -eq 'object')
        {
            $model.TypeName = '{0}.{1}' -f $ClientName, $typed.RefName
            $model.OutputType = "'$($model.TypeName)'"
        } else
        {
            $model.OutputType = '[pscustomobject]'
        }
        return $model
    }

    $isBinary = @($content.Keys | Where-Object { $_ -match '^(audio|image|video)/|octet-stream|pdf|zip' }).Count -gt 0
    if ($isBinary)
    {
        $model.Kind = 'binary'
        $model.OutputType = '[System.IO.FileInfo]'
    } else
    {
        $model.Kind = 'text'
        $model.OutputType = '[string], [System.IO.FileInfo]'
    }
    $model
}

function New-OpenApiOperationModel
{
    <#
    .SYNOPSIS
    Builds the emission model for one named operation record (see Resolve-OpenApiFunctionName).

    .DESCRIPTION
    Path/query/header parameters and the top-level properties of a JSON/form/multipart body are
    flattened into one parameter list. Non-object bodies become a single -Body parameter. Bodies
    with properties also get an InputObject parameter set (hashtable/object/primary string via pipeline).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document,

        [Parameter(Mandatory)]
        [pscustomobject]$Record,

        [Parameter(Mandatory)]
        [string]$ClientName,

        [Parameter()]
        [string[]]$RawPathParameter = @()
    )

    $operation = $Record.Operation
    $descriptors = [System.Collections.Generic.List[object]]::new()

    foreach ($parameter in $Record.Parameters)
    {
        if ($parameter['in'] -notin 'path', 'query', 'header')
        {
            Write-Verbose "Skipping $($parameter['in']) parameter '$($parameter['name'])' on $($Record.Name)"
            continue
        }
        $schema = if ($parameter.Contains('schema')) { $parameter['schema'] } else { @{} }
        $typeInfo = Get-OpenApiTypeInfo -Document $Document -Schema $schema
        $required = ($parameter['in'] -eq 'path') -or ($parameter['required'] -eq $true)
        $descriptor = New-OpenApiParameterDescriptor -Wire $parameter['name'] -In $parameter['in'] -TypeInfo $typeInfo -Mandatory:$required -Description ([string]$parameter['description']) -Style ([string]$parameter['style'])
        if ($typeInfo.Kind -eq 'array' -and $parameter['in'] -eq 'query' -and $parameter.Contains('explode') -and $parameter['explode'] -eq $false)
        {
            $descriptor.Csv = $true
        }
        $descriptors.Add($descriptor)
    }

    # Body ------------------------------------------------------------------
    $bodyKind = 'none'
    $bodyDescriptors = @()
    $primaryBodyProperty = $null
    $requestBody = Resolve-OpenApiObject -Document $Document -Object $operation['requestBody']
    if ($requestBody -and $requestBody['content'])
    {
        $content = $requestBody['content']
        $contentKey = foreach ($preferred in 'application/json', 'multipart/form-data', 'application/x-www-form-urlencoded')
        {
            if ($content.Contains($preferred))
            {
                $preferred
                break
            }
        }
        if (-not $contentKey)
        {
            $contentKey = @($content.Keys | Where-Object { $_ -match 'json' }) | Select-Object -First 1
        }
        if (-not $contentKey)
        {
            $contentKey = @($content.Keys) | Select-Object -First 1
        }
        $bodyRequired = ($requestBody['required'] -eq $true)
        $typeInfo = Get-OpenApiTypeInfo -Document $Document -Schema $content[$contentKey]['schema']

        $bodyKind = switch -Wildcard ($contentKey)
        {
            'multipart/*' { 'multipart' }
            '*x-www-form-urlencoded' { 'form' }
            '*json' { 'json' }
            default { 'json' }
        }

        if ($typeInfo.Kind -eq 'object' -and $typeInfo.Properties.Count -gt 0)
        {
            $bodyDescriptors = foreach ($propertyName in $typeInfo.Properties.Keys)
            {
                $propertyInfo = $typeInfo.Properties[$propertyName]
                New-OpenApiParameterDescriptor -Wire $propertyName -In body -TypeInfo $propertyInfo -Mandatory:($propertyName -in $typeInfo.Required)
            }
            $requiredStrings = @($bodyDescriptors | Where-Object { $_.Mandatory -and $_.TypeInfo.Kind -eq 'string' -and -not $_.TypeInfo.Enum })
            if ($requiredStrings.Count -eq 1 -and $bodyKind -eq 'json')
            {
                $primaryBodyProperty = $requiredStrings[0].Wire
            }
        } else
        {
            # A raw value (array/string) or free-form object: single -Body parameter.
            $bodyDescriptors = @(New-OpenApiParameterDescriptor -Wire 'body' -In body -TypeInfo $typeInfo -Mandatory:$bodyRequired -Description $(if ($typeInfo.Description) { $typeInfo.Description } else { 'The request body.' }))
            $bodyKind = if ($bodyKind -eq 'json') { 'rootvalue' } else { $bodyKind }
        }
        $descriptors.AddRange([object[]]@($bodyDescriptors))
    }

    # Order: path, then required, then optional (stable within each group).
    $path = @($descriptors | Where-Object In -EQ 'path')
    $others = @($descriptors | Where-Object In -NE 'path')
    $ordered = @($path) + @($others | Where-Object Mandatory) + @($others | Where-Object { -not $_.Mandatory })
    Set-OpenApiParameterName -Descriptor $ordered

    $response = Get-OpenApiResponseModel -Document $Document -Operation $operation -Method $Record.Method -ClientName $ClientName

    # Catch-all routes (/proxy/{path}) must keep their slashes; only an explicit or catch-all-looking trailing parameter does.
    $catchAll = '^\*{0,2}(path|filepath|file_path|catchall|catch_all|rest|wildcard|remainder)$'
    $rawPath = @($descriptors | Where-Object {
            $_.In -eq 'path' -and ($_.Wire -in $RawPathParameter -or ($_.Wire -match $catchAll -and $Record.Path -match "\{$([regex]::Escape($_.Wire))\}/?$"))
        } | ForEach-Object { $_.Wire })
    $hasInputObject = ($bodyKind -in 'json', 'form') -and @($bodyDescriptors | Where-Object { $_.In -eq 'body' }).Count -gt 0 -and $bodyKind -ne 'rootvalue'

    [pscustomobject]@{
        Name                = $Record.Name
        Method              = $Record.Method
        Path                = $Record.Path
        Summary             = [string]$operation['summary']
        Description         = [string]$operation['description']
        Deprecated          = ($operation['deprecated'] -eq $true)
        Parameter           = $ordered
        BodyKind            = $bodyKind
        HasInputObject      = $hasInputObject
        PrimaryBodyProperty = $primaryBodyProperty
        Response            = $response
        RawPath             = $rawPath
        SupportsOutFile     = ($response.Kind -in 'unknown', 'binary', 'text')
        ShouldProcess       = ($Record.Method -in 'DELETE', 'PUT', 'PATCH')
        ConfirmImpact       = if ($Record.Method -eq 'DELETE') { 'High' } else { 'Medium' }
    }
}
