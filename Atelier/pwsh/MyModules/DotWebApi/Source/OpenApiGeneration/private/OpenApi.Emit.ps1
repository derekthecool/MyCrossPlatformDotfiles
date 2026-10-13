# Source-code emitters for New-OpenApiClient. Everything returns LF-joined strings in the module's Allman style.

function Format-OpenApiHelpText
{
    <#
    .SYNOPSIS
    Makes arbitrary spec text safe inside a comment-based-help block and indents it.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Text,

        [Parameter()]
        [string]$Indent = '    '
    )

    if (-not $Text)
    {
        return @()
    }
    $safe = $Text.Replace('#>', '# >').Replace('<#', '< #')
    foreach ($line in ($safe -split "\r?\n"))
    {
        ($Indent + $line).TrimEnd()
    }
}

function Get-OpenApiExampleValue
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Descriptor
    )

    if ($Descriptor.Allowed)
    {
        return ConvertTo-OpenApiLiteral -Value @($Descriptor.Allowed)[0]
    }
    if ($Descriptor.IsFile)
    {
        return "'./file'"
    }
    switch -Wildcard ($Descriptor.Type)
    {
        '`[string`]' { return "'example'" }
        '`[int`]' { return '1' }
        '`[long`]' { return '1' }
        '`[double`]' { return '1.0' }
        '`[bool`]' { return '$true' }
        '`[switch`]' { return $null }
        '*`[`]`]' { return "'a', 'b'" }
        default { return '@{ }' }
    }
}

function Format-OpenApiParameterSource
{
    <#
    .SYNOPSIS
    Emits one [Parameter()] declaration block (attributes, validation, type, name).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Descriptor,

        [Parameter()]
        [string]$ParameterSetName,

        [Parameter()]
        [switch]$ByPropertyName
    )

    $attribute = [System.Collections.Generic.List[string]]::new()
    if ($Descriptor.Mandatory)
    {
        $attribute.Add('Mandatory')
    }
    if ($ParameterSetName)
    {
        $attribute.Add("ParameterSetName = '$ParameterSetName'")
    }
    if ($ByPropertyName)
    {
        $attribute.Add('ValueFromPipelineByPropertyName')
    }

    "        [Parameter($($attribute -join ', '))]"
    if (@($Descriptor.Alias).Count -gt 0)
    {
        "        [Alias($((@($Descriptor.Alias) | ForEach-Object { ConvertTo-OpenApiLiteral -Value $_ }) -join ', '))]"
    }
    foreach ($line in $Descriptor.Validate)
    {
        "        $line"
    }
    "        $($Descriptor.Type)`$$($Descriptor.Name)"
}

function Format-OpenApiParameterHelp
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Descriptor,

        [Parameter()]
        [string]$WireNote
    )

    ".PARAMETER $($Descriptor.Name)"
    $text = if ($Descriptor.Description) { $Descriptor.Description } else { "The '$($Descriptor.Wire)' $($Descriptor.In) value." }
    Format-OpenApiHelpText -Text $text -Indent ''
    if ($Descriptor.Allowed)
    {
        "Allowed values: $((@($Descriptor.Allowed) | ForEach-Object { [string]$_ }) -join ', ')."
    }
    if ($Descriptor.Default)
    {
        "Server default: $($Descriptor.Default)."
    }
    if ($WireNote)
    {
        $WireNote
    }
    ''
}

function ConvertTo-OpenApiFunctionSource
{
    <#
    .SYNOPSIS
    Emits the PowerShell function for one operation model.

    .PARAMETER ClientVariable
    Name of the script-scope ClientInfo hashtable, e.g. KokoroClientInfo.

    .PARAMETER RuntimeName
    Name of the request runtime function (module or embedded variant).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Model,

        [Parameter(Mandatory)]
        [string]$ClientVariable,

        [Parameter(Mandatory)]
        [string]$BodyTableName,

        [Parameter(Mandatory)]
        [string]$RuntimeName
    )

    $nl = "`n"
    $out = [System.Collections.Generic.List[string]]::new()
    $parameters = @($Model.Parameter)
    $bodyParameters = @($parameters | Where-Object In -EQ 'body')
    $summary = if ($Model.Summary) { $Model.Summary } else { "$($Model.Method) $($Model.Path)" }

    $out.Add("function $($Model.Name)")
    $out.Add('{')

    # --- help ---------------------------------------------------------------
    $out.Add('    <#')
    $out.Add('    .SYNOPSIS')
    $out.AddRange([string[]]@(Format-OpenApiHelpText -Text $summary))
    $out.Add('')
    $out.Add('    .DESCRIPTION')
    if ($Model.Description -and $Model.Description.Trim() -ne $summary)
    {
        $out.AddRange([string[]]@(Format-OpenApiHelpText -Text $Model.Description.Trim()))
        $out.Add('')
    }
    $out.Add("    Calls $($Model.Method) $($Model.Path).")
    if ($Model.Deprecated)
    {
        $out.Add('    This operation is marked deprecated in the API description.')
    }
    $out.Add('')
    foreach ($descriptor in $parameters)
    {
        $wire = if ($descriptor.Name -ne $descriptor.Wire) { "Sent as '$($descriptor.Wire)'." } else { $null }
        foreach ($line in Format-OpenApiParameterHelp -Descriptor $descriptor -WireNote $wire)
        {
            $out.Add(('    ' + $line).TrimEnd())
        }
    }
    if ($Model.HasInputObject)
    {
        $out.Add('    .PARAMETER InputObject')
        $out.Add('    A hashtable or object whose properties are sent as the request body. Keys may be this command''s parameter names or the API''s own property names.')
        $out.Add('    All piped input is received here, so one command can process many requests from the pipeline.')
        if ($Model.PrimaryBodyProperty)
        {
            $out.Add("    A plain string is treated as the '$($Model.PrimaryBodyProperty)' property.")
        }
        $out.Add('    Individually specified parameters override matching keys.')
        $out.Add('')
    }
    $out.Add('    .PARAMETER Endpoint')
    $out.Add('    Base URL of the API. Defaults to the saved/default endpoint (see the *DefaultEndpoint commands).')
    $out.Add('')
    $out.Add('    .PARAMETER Credential')
    $out.Add('    Credential for the API; the password is used as the token/key when the API uses one.')
    $out.Add('')
    $out.Add('    .PARAMETER Headers')
    $out.Add('    Extra request headers.')
    $out.Add('')
    $out.Add('    .PARAMETER TimeoutSec')
    $out.Add('    Request timeout in seconds (default 100).')
    $out.Add('')
    if ($Model.SupportsOutFile)
    {
        $out.Add('    .PARAMETER OutFile')
        $out.Add('    Save the response body to this file (or into this directory). Binary responses without -OutFile are saved to a temp file.')
        $out.Add('')
    }

    $mandatory = @($parameters | Where-Object Mandatory)
    $example = "$($Model.Name)"
    foreach ($descriptor in $mandatory)
    {
        $value = Get-OpenApiExampleValue -Descriptor $descriptor
        if ($value)
        {
            $example += " -$($descriptor.Name) $value"
        }
    }
    if ($Model.SupportsOutFile)
    {
        $example += ' -OutFile ./output.bin'
    }
    $out.Add('    .EXAMPLE')
    $out.Add("    $example")
    $out.Add('')
    if ($Model.HasInputObject -and $Model.PrimaryBodyProperty)
    {
        $out.Add('    .EXAMPLE')
        $out.Add("    'example' | $($Model.Name)$(if ($Model.SupportsOutFile) { ' -OutFile ./output.bin' })")
        $out.Add('')
    }
    if ($Model.Response.OutputType)
    {
        $out.Add('    .OUTPUTS')
        $out.Add("    $($Model.Response.OutputType -replace '[\[\]]', '' -replace "'", '')")
        $out.Add('')
    }
    $out.Add('    .LINK')
    $out.Add("    $($Model.Method) $($Model.Path)")
    $out.Add('    #>')

    # --- attributes -----------------------------------------------------------
    $binding = [System.Collections.Generic.List[string]]::new()
    # No DefaultParameterSetName: with one, piped strings/hashtables cannot reach the InputObject set.
    if ($Model.ShouldProcess)
    {
        $binding.Add('SupportsShouldProcess')
        $binding.Add("ConfirmImpact = '$($Model.ConfirmImpact)'")
    }
    $out.Add("    [CmdletBinding($($binding -join ', '))]")
    if ($Model.Response.OutputType)
    {
        $out.Add("    [OutputType($($Model.Response.OutputType))]")
    }
    $out.Add('    param(')

    $blocks = [System.Collections.Generic.List[object]]::new()
    foreach ($descriptor in $parameters)
    {
        # Body properties bind only by name on the command line; piped objects arrive through -InputObject.
        # Only mandatory body properties pin the 'Properties' set; optional ones work with either set, so a piped
        # object can still be combined with explicit overrides such as -Voice.
        $viaInputObject = $descriptor.In -eq 'body' -and $Model.HasInputObject
        $set = if ($viaInputObject -and $descriptor.Mandatory) { 'Properties' } else { $null }
        $blocks.Add(@(Format-OpenApiParameterSource -Descriptor $descriptor -ParameterSetName $set -ByPropertyName:(-not $viaInputObject)))
    }
    if ($Model.HasInputObject)
    {
        # With required body properties two sets keep "give properties" and "give an object" mutually exclusive.
        # With none, sets are unnecessary (and make a bare call ambiguous), so -InputObject is simply optional.
        $anyRequired = @($parameters | Where-Object { $_.In -eq 'body' -and $_.Mandatory }).Count -gt 0
        $inputAttribute = if ($anyRequired) { "        [Parameter(Mandatory, ParameterSetName = 'InputObject', ValueFromPipeline)]" } else { '        [Parameter(ValueFromPipeline)]' }
        $blocks.Add(@($inputAttribute, '        [object]$InputObject'))
    }
    $blocks.Add(@(
            '        [Parameter()]'
            "        [ValidatePattern('^https?://')]"
            '        [string]$Endpoint'
        ))
    $blocks.Add(@(
            '        [Parameter()]'
            '        [System.Management.Automation.Credential()]'
            '        [pscredential]$Credential'
        ))
    $blocks.Add(@(
            '        [Parameter()]'
            '        [hashtable]$Headers'
        ))
    $blocks.Add(@(
            '        [Parameter()]'
            '        [ValidateRange(0, 86400)]'
            '        [int]$TimeoutSec'
        ))
    if ($Model.SupportsOutFile)
    {
        $blocks.Add(@(
                '        [Parameter()]'
                '        [string]$OutFile'
            ))
    }
    for ($i = 0; $i -lt $blocks.Count; $i++)
    {
        $lines = @($blocks[$i])
        if ($i -lt $blocks.Count - 1)
        {
            $lines[-1] += ','
        }
        $out.AddRange([string[]]$lines)
        if ($i -lt $blocks.Count - 1)
        {
            $out.Add('')
        }
    }
    $out.Add('    )')
    $out.Add('')

    # --- body -----------------------------------------------------------------
    $out.Add('    process')
    $out.Add('    {')

    $valueOf = { param($d) if ($d.IsSwitch) { "[bool]`$$($d.Name)" } else { "`$$($d.Name)" } }

    $request = [System.Collections.Generic.List[object]]::new()
    $request.Add(@('ClientInfo', "`$Script:$ClientVariable"))
    $request.Add(@('Method', "$(ConvertTo-OpenApiLiteral -Value $Model.Method)"))
    $request.Add(@('PathTemplate', "$(ConvertTo-OpenApiLiteral -Value $Model.Path)"))

    $pathDescriptors = @($parameters | Where-Object In -EQ 'path')
    if ($pathDescriptors.Count -gt 0)
    {
        $out.Add('        $pathParameter = @{}')
        foreach ($d in $pathDescriptors)
        {
            $out.Add("        `$pathParameter[$(ConvertTo-OpenApiLiteral -Value $d.Wire)] = $(& $valueOf $d)")
        }
        $out.Add('')
        $request.Add(@('PathParameter', '$pathParameter'))
        if (@($Model.RawPath).Count -gt 0)
        {
            $request.Add(@('RawPathName', (ConvertTo-OpenApiLiteral -Value @($Model.RawPath))))
        }
    }

    foreach ($location in 'query', 'header')
    {
        $group = @($parameters | Where-Object In -EQ $location)
        if ($group.Count -eq 0)
        {
            continue
        }
        $variable = if ($location -eq 'query') { 'query' } else { 'headerParameter' }
        $out.Add("        `$$variable = [ordered]@{}")
        foreach ($d in $group)
        {
            $assign = "`$$variable[$(ConvertTo-OpenApiLiteral -Value $d.Wire)] = $(& $valueOf $d)"
            if ($d.Mandatory)
            {
                $out.Add("        $assign")
            } else
            {
                $out.Add("        if (`$PSBoundParameters.ContainsKey('$($d.Name)')) { $assign }")
            }
        }
        $out.Add('')
        if ($location -eq 'query')
        {
            $request.Add(@('Query', '$query'))
            $csv = @($group | Where-Object Csv | ForEach-Object { $_.Wire })
            if ($csv.Count -gt 0)
            {
                $request.Add(@('CsvQueryName', "$(ConvertTo-OpenApiLiteral -Value $csv)"))
            }
        } else
        {
            $request.Add(@('HeaderParameter', '$headerParameter'))
        }
    }

    switch ($Model.BodyKind)
    {
        { $_ -in 'json', 'form' }
        {
            if ($Model.HasInputObject)
            {
                $primary = if ($Model.PrimaryBodyProperty) { " -PrimaryProperty $(ConvertTo-OpenApiLiteral -Value $Model.PrimaryBodyProperty)" } else { '' }
                $mapped = @($bodyParameters | Where-Object { $_.Name -cne $_.Wire })
                $out.Add("        if (`$PSBoundParameters.ContainsKey('InputObject'))")
                $out.Add('        {')
                $mapArgument = ''
                if ($mapped.Count -gt 0)
                {
                    $width = ($mapped | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
                    $out.Add('            $propertyMap = @{')
                    foreach ($d in $mapped)
                    {
                        $out.Add("                $($d.Name.PadRight($width)) = $(ConvertTo-OpenApiLiteral -Value $d.Wire)")
                    }
                    $out.Add('            }')
                    $mapArgument = ' -PropertyMap $propertyMap'
                }
                $out.Add("            `$body = $BodyTableName -InputObject `$InputObject$mapArgument$primary")
                $out.Add('        } else')
                $out.Add('        {')
                $out.Add('            $body = [ordered]@{}')
                $out.Add('        }')
            } else
            {
                $out.Add('        $body = [ordered]@{}')
            }
            foreach ($d in $bodyParameters)
            {
                $out.Add("        if (`$PSBoundParameters.ContainsKey('$($d.Name)')) { `$body[$(ConvertTo-OpenApiLiteral -Value $d.Wire)] = $(& $valueOf $d) }")
            }
            $requiredWire = @($bodyParameters | Where-Object Mandatory | ForEach-Object { $_.Wire })
            if ($Model.HasInputObject -and $requiredWire.Count -gt 0)
            {
                $out.Add("        foreach (`$required in $(ConvertTo-OpenApiLiteral -Value $requiredWire))")
                $out.Add('        {')
                $out.Add('            if (-not $body.Contains($required))')
                $out.Add('            {')
                $out.Add("                throw `"$($Model.Name): the request is missing required property '`$required'.`"")
                $out.Add('            }')
                $out.Add('        }')
            }
            $out.Add('')
            $request.Add(@('Body', '$body'))
            if ($Model.BodyKind -eq 'form')
            {
                $request.Add(@('BodyType', "'form'"))
            }
        }
        'multipart'
        {
            $out.Add('        $body = [ordered]@{}')
            foreach ($d in $bodyParameters)
            {
                $source = if ($d.IsFile) { "(Get-Item -LiteralPath `$$($d.Name))" } else { & $valueOf $d }
                $assign = "`$body[$(ConvertTo-OpenApiLiteral -Value $d.Wire)] = $source"
                if ($d.Mandatory)
                {
                    $out.Add("        $assign")
                } else
                {
                    $out.Add("        if (`$PSBoundParameters.ContainsKey('$($d.Name)')) { $assign }")
                }
            }
            $out.Add('')
            $request.Add(@('Body', '$body'))
            $request.Add(@('BodyType', "'multipart'"))
        }
        'rootvalue'
        {
            $d = $bodyParameters[0]
            if ($d.Mandatory)
            {
                $request.Add(@('Body', "`$$($d.Name)"))
            } else
            {
                $out.Add("        `$body = if (`$PSBoundParameters.ContainsKey('$($d.Name)')) { `$$($d.Name) } else { `$null }")
                $out.Add('')
                $request.Add(@('Body', '$body'))
            }
        }
    }

    if ($Model.Response.TypeName)
    {
        $request.Add(@('ResultType', "$(ConvertTo-OpenApiLiteral -Value $Model.Response.TypeName)"))
    }

    $out.Add('        $request = @{')
    $keyWidth = ($request | ForEach-Object { $_[0].Length } | Measure-Object -Maximum).Maximum
    foreach ($pair in $request)
    {
        $out.Add('            ' + $pair[0].PadRight($keyWidth) + ' = ' + $pair[1])
    }
    $out.Add('        }')
    $out.Add("        foreach (`$common in 'Endpoint', 'Credential', 'Headers', 'TimeoutSec', 'OutFile')")
    $out.Add('        {')
    $out.Add('            if ($PSBoundParameters.ContainsKey($common))')
    $out.Add('            {')
    $out.Add('                $request[$common] = $PSBoundParameters[$common]')
    $out.Add('            }')
    $out.Add('        }')
    $out.Add('')
    if ($Model.ShouldProcess)
    {
        $out.Add("        if (-not `$PSCmdlet.ShouldProcess($(ConvertTo-OpenApiLiteral -Value "$($Model.Method) $($Model.Path)"), $(ConvertTo-OpenApiLiteral -Value $Model.Name)))")
        $out.Add('        {')
        $out.Add('            return')
        $out.Add('        }')
        $out.Add('')
    }
    $out.Add("        $RuntimeName @request")
    $out.Add('    }')
    $out.Add('}')

    $out -join $nl
}

function ConvertTo-OpenApiConstructorSource
{
    <#
    .SYNOPSIS
    Emits a New-<Prefix><Type> function that builds a PSTypeName-tagged object for a named object schema.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        [string]$TypeName,

        [Parameter(Mandatory)]
        [pscustomobject]$TypeInfo
    )

    $descriptors = foreach ($propertyName in $TypeInfo.Properties.Keys)
    {
        New-OpenApiParameterDescriptor -Wire $propertyName -In ctor -TypeInfo $TypeInfo.Properties[$propertyName] -Mandatory:($propertyName -in $TypeInfo.Required)
    }
    $descriptors = @($descriptors | Where-Object Mandatory) + @($descriptors | Where-Object { -not $_.Mandatory })
    Set-OpenApiParameterName -Descriptor $descriptors

    $out = [System.Collections.Generic.List[string]]::new()
    $out.Add("function $FunctionName")
    $out.Add('{')
    $out.Add('    <#')
    $out.Add('    .SYNOPSIS')
    $out.Add("    Creates a $TypeName object for use as an API request value.")
    $out.Add('')
    $out.Add('    .DESCRIPTION')
    if ($TypeInfo.Description)
    {
        $out.AddRange([string[]]@(Format-OpenApiHelpText -Text $TypeInfo.Description))
        $out.Add('')
    }
    $out.Add("    Only the properties you pass are included, so the API's own defaults apply to the rest.")
    $out.Add('')
    foreach ($descriptor in $descriptors)
    {
        $wire = if ($descriptor.Name -ne $descriptor.Wire) { "Sent as '$($descriptor.Wire)'." } else { $null }
        foreach ($line in Format-OpenApiParameterHelp -Descriptor $descriptor -WireNote $wire)
        {
            $out.Add(('    ' + $line).TrimEnd())
        }
    }
    $example = $FunctionName
    foreach ($descriptor in $descriptors | Where-Object Mandatory)
    {
        $value = Get-OpenApiExampleValue -Descriptor $descriptor
        if ($value)
        {
            $example += " -$($descriptor.Name) $value"
        }
    }
    $out.Add('    .EXAMPLE')
    $out.Add("    $example")
    $out.Add('')
    $out.Add('    .OUTPUTS')
    $out.Add("    $TypeName")
    $out.Add('    #>')
    $out.Add('    [CmdletBinding()]')
    $out.Add("    [OutputType($(ConvertTo-OpenApiLiteral -Value $TypeName))]")
    $out.Add('    param(')
    for ($i = 0; $i -lt $descriptors.Count; $i++)
    {
        $lines = @(Format-OpenApiParameterSource -Descriptor $descriptors[$i])
        if ($i -lt $descriptors.Count - 1)
        {
            $lines[-1] += ','
        }
        $out.AddRange([string[]]$lines)
        if ($i -lt $descriptors.Count - 1)
        {
            $out.Add('')
        }
    }
    $out.Add('    )')
    $out.Add('')
    $out.Add('    process')
    $out.Add('    {')
    $out.Add("        `$result = [ordered]@{ PSTypeName = $(ConvertTo-OpenApiLiteral -Value $TypeName) }")
    foreach ($descriptor in $descriptors)
    {
        $value = if ($descriptor.IsSwitch) { "[bool]`$$($descriptor.Name)" } else { "`$$($descriptor.Name)" }
        $out.Add("        if (`$PSBoundParameters.ContainsKey('$($descriptor.Name)')) { `$result[$(ConvertTo-OpenApiLiteral -Value $descriptor.Wire)] = $value }")
    }
    $out.Add('        [pscustomobject]$result')
    $out.Add('    }')
    $out.Add('}')
    $out -join "`n"
}

function ConvertTo-OpenApiConfigSource
{
    <#
    .SYNOPSIS
    Emits Get/Set/Clear-<Prefix>DefaultEndpoint and Set-<Prefix>Credential for a generated client.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix,

        [Parameter(Mandatory)]
        [string]$ClientVariable
    )

    @"
function Get-${Prefix}DefaultEndpoint
{
    <#
    .SYNOPSIS
    Shows the endpoint that $Prefix commands will use.

    .DESCRIPTION
    Resolution order: -Endpoint on a command, the ${Prefix}_ENDPOINT environment variable (upper-cased),
    the endpoint saved with Set-${Prefix}DefaultEndpoint, the default baked in when the client was
    generated, then the server listed in the API description.

    .EXAMPLE
    Get-${Prefix}DefaultEndpoint

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    process
    {
        Resolve-OpenApiEndpoint -ClientInfo `$Script:$ClientVariable
    }
}

function Set-${Prefix}DefaultEndpoint
{
    <#
    .SYNOPSIS
    Saves the default endpoint for $Prefix commands.

    .DESCRIPTION
    Stores the endpoint in your home directory so it is used by every session until it is cleared.
    The ${Prefix}_ENDPOINT environment variable and -Endpoint on a command still take precedence.

    .PARAMETER Endpoint
    Base URL such as http://host:8880.

    .EXAMPLE
    Set-${Prefix}DefaultEndpoint http://localhost:8880
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^https?://')]
        [string]`$Endpoint
    )

    process
    {
        if (`$PSCmdlet.ShouldProcess(`$Endpoint, 'Save default $Prefix endpoint'))
        {
            Set-OpenApiClientSetting -ClientInfo `$Script:$ClientVariable -Endpoint `$Endpoint -Confirm:`$false
        }
    }
}

function Clear-${Prefix}DefaultEndpoint
{
    <#
    .SYNOPSIS
    Removes the saved default endpoint for $Prefix commands.

    .DESCRIPTION
    Deletes the file written by Set-${Prefix}DefaultEndpoint; commands fall back to the endpoint
    baked in at generation time or the server listed in the API description.

    .EXAMPLE
    Clear-${Prefix}DefaultEndpoint
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    process
    {
        if (`$PSCmdlet.ShouldProcess('$Prefix', 'Remove saved endpoint'))
        {
            Clear-OpenApiClientSetting -ClientInfo `$Script:$ClientVariable -Confirm:`$false
        }
    }
}

function Set-${Prefix}Credential
{
    <#
    .SYNOPSIS
    Sets (or, with no argument, clears) the credential $Prefix commands use for this session.

    .DESCRIPTION
    The credential is kept in memory only. How it is sent depends on the API's security scheme
    (basic, bearer token, or API key); -Credential on an individual command overrides it.
    With -FromSecret the key is read once from a Microsoft.PowerShell.SecretManagement secret
    (this is the only place a vault is touched, so no command ever prompts for a vault password on its own).

    .PARAMETER Credential
    The credential. Its password is used as the token or key for the API.

    .PARAMETER FromSecret
    Read the key from a SecretManagement secret instead of passing a credential.

    .PARAMETER SecretName
    Name of the secret for -FromSecret (default: ${Prefix}ApiKey).

    .EXAMPLE
    Set-${Prefix}Credential (Get-Credential)

    .EXAMPLE
    Set-${Prefix}Credential -FromSecret
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Credential')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Credential')]
        [System.Management.Automation.Credential()]
        [pscredential]`$Credential,

        [Parameter(Mandatory, ParameterSetName = 'Secret')]
        [switch]`$FromSecret,

        [Parameter(ParameterSetName = 'Secret')]
        [string]`$SecretName = '${Prefix}ApiKey'
    )

    process
    {
        if (`$PSCmdlet.ShouldProcess('$Prefix', 'Set session credential'))
        {
            if (`$PSCmdlet.ParameterSetName -eq 'Secret')
            {
                Set-OpenApiClientCredential -ClientInfo `$Script:$ClientVariable -SecretName `$SecretName -Confirm:`$false
            } else
            {
                Set-OpenApiClientCredential -ClientInfo `$Script:$ClientVariable -Credential `$Credential -Confirm:`$false
            }
        }
    }
}
"@ -replace "`r`n", "`n"
}
