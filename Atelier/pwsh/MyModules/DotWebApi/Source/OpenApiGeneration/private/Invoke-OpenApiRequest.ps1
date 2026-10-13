# Shared request runtime for clients made by the DotWebApi generator.
#
# In -RuntimeMode Embedded this file is copied next to the generated clients with every identifier
# renamed to <RuntimeName>Api* (a plain text replacement, so keep that stem out of comments and strings
# you do not want renamed). Keep it self-contained: no calls into the rest of DotWebApi.

$Script:OpenApiSessionCredential = @{}

$Script:OpenApiMimeExtension = @{
    'audio/mpeg'               = '.mp3'
    'audio/mp3'                = '.mp3'
    'audio/wav'                = '.wav'
    'audio/x-wav'              = '.wav'
    'audio/wave'               = '.wav'
    'audio/ogg'                = '.ogg'
    'audio/opus'               = '.opus'
    'audio/aac'                = '.aac'
    'audio/flac'               = '.flac'
    'audio/x-flac'             = '.flac'
    'audio/l16'                = '.pcm'
    'audio/pcm'                = '.pcm'
    'application/pdf'          = '.pdf'
    'application/zip'          = '.zip'
    'image/png'                = '.png'
    'image/jpeg'               = '.jpg'
    'image/gif'                = '.gif'
    'image/svg+xml'            = '.svg'
    'video/mp4'                = '.mp4'
    'application/octet-stream' = '.bin'
}

function Get-OpenApiClientSettingPath
{
    <#
    .SYNOPSIS
    Returns the CLIXML path used to persist settings for a generated client.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ClientInfo
    )

    Join-Path -Path $HOME -ChildPath ('.{0}_config.xml' -f $ClientInfo.ApiName.ToLowerInvariant())
}

function Get-OpenApiClientSetting
{
    <#
    .SYNOPSIS
    Reads persisted settings (currently only Endpoint) for a generated client.

    .OUTPUTS
    Hashtable; empty when nothing has been saved.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ClientInfo
    )

    $path = Get-OpenApiClientSettingPath -ClientInfo $ClientInfo
    if (-not (Test-Path -LiteralPath $path))
    {
        return @{}
    }

    try
    {
        $settings = Import-Clixml -LiteralPath $path
        if ($settings -is [hashtable])
        {
            return $settings
        }
    } catch
    {
        Write-Verbose "Could not read settings from ${path}: $_"
    }
    @{}
}

function Set-OpenApiClientSetting
{
    <#
    .SYNOPSIS
    Persists the default endpoint for a generated client.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ClientInfo,

        [Parameter(Mandatory)]
        [ValidatePattern('^https?://')]
        [string]$Endpoint
    )

    $path = Get-OpenApiClientSettingPath -ClientInfo $ClientInfo
    $settings = Get-OpenApiClientSetting -ClientInfo $ClientInfo
    $settings.Endpoint = $Endpoint.TrimEnd('/')
    $settings.UpdatedAt = Get-Date

    if ($PSCmdlet.ShouldProcess($path, "Save default endpoint $($settings.Endpoint)"))
    {
        $settings | Export-Clixml -LiteralPath $path -Force
        Write-Verbose "Default endpoint for $($ClientInfo.ApiName) saved to $path"
    }
}

function Clear-OpenApiClientSetting
{
    <#
    .SYNOPSIS
    Removes persisted settings for a generated client.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ClientInfo
    )

    $path = Get-OpenApiClientSettingPath -ClientInfo $ClientInfo
    if ((Test-Path -LiteralPath $path) -and $PSCmdlet.ShouldProcess($path, 'Remove saved settings'))
    {
        Remove-Item -LiteralPath $path -Force
    }
}

function Set-OpenApiClientCredential
{
    <#
    .SYNOPSIS
    Stores (or clears, when no credential is given) the session credential for a generated client.

    .DESCRIPTION
    With -SecretName the key is read once from a SecretManagement secret. Reading happens only here,
    never implicitly while sending requests, so a locked vault cannot make a command prompt unexpectedly.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Credential')]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ClientInfo,

        [Parameter(ParameterSetName = 'Credential')]
        [pscredential]$Credential,

        [Parameter(Mandatory, ParameterSetName = 'Secret')]
        [string]$SecretName
    )

    if ($PSCmdlet.ParameterSetName -eq 'Secret')
    {
        if (-not (Get-Command -Name Get-Secret -ErrorAction SilentlyContinue))
        {
            throw 'Microsoft.PowerShell.SecretManagement is not available; install it or pass -Credential.'
        }
        $key = Get-Secret -Name $SecretName -AsPlainText -ErrorAction Stop
        $secure = [System.Security.SecureString]::new()
        foreach ($character in ([string]$key).ToCharArray())
        {
            $secure.AppendChar($character)
        }
        $secure.MakeReadOnly()
        $Credential = [pscredential]::new($ClientInfo.ApiName, $secure)
    }

    if ($PSCmdlet.ShouldProcess($ClientInfo.ApiName, 'Set session credential'))
    {
        if ($Credential)
        {
            $Script:OpenApiSessionCredential[$ClientInfo.ApiName] = $Credential
        } else
        {
            $Script:OpenApiSessionCredential.Remove($ClientInfo.ApiName)
        }
    }
}

function Resolve-OpenApiEndpoint
{
    <#
    .SYNOPSIS
    Picks the endpoint: parameter, env var, saved setting, generation-time default, spec server.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ClientInfo,

        [Parameter()]
        [string]$Endpoint
    )

    $value = $null
    $fromServer = $false

    if ($Endpoint)
    {
        $value = $Endpoint
    } else
    {
        $envName = '{0}_ENDPOINT' -f ($ClientInfo.ApiName.ToUpperInvariant() -replace '[^A-Z0-9]', '_')
        $envValue = [Environment]::GetEnvironmentVariable($envName)
        $saved = (Get-OpenApiClientSetting -ClientInfo $ClientInfo).Endpoint

        if ($envValue)
        {
            $value = $envValue
        } elseif ($saved)
        {
            $value = $saved
        } elseif ($ClientInfo.DefaultEndpoint)
        {
            $value = $ClientInfo.DefaultEndpoint
        } elseif ($ClientInfo.ServerUrl -match '^https?://')
        {
            $value = $ClientInfo.ServerUrl
            $fromServer = $true
        }
    }

    if (-not $value)
    {
        throw "No endpoint configured for $($ClientInfo.ApiName). Pass -Endpoint, set the $($ClientInfo.ApiName.ToUpperInvariant())_ENDPOINT environment variable, or run Set-$($ClientInfo.ApiName)DefaultEndpoint."
    }

    $value = $value.TrimEnd('/')
    $basePath = $ClientInfo.BasePath
    if ($basePath -and -not $fromServer -and -not $value.EndsWith($basePath))
    {
        $value += $basePath
    }
    $value
}

function ConvertTo-OpenApiQueryValue
{
    <#
    .SYNOPSIS
    Formats a scalar for use in a query string / header (lowercase booleans, ISO dates, invariant numbers).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value
    )

    if ($Value -is [bool])
    {
        return $Value.ToString().ToLowerInvariant()
    }
    if ($Value -is [datetime])
    {
        return $Value.ToString('o')
    }
    if ($Value -is [System.IFormattable])
    {
        return $Value.ToString($null, [cultureinfo]::InvariantCulture)
    }
    [string]$Value
}

function ConvertTo-OpenApiBodyTable
{
    <#
    .SYNOPSIS
    Normalises an -InputObject (hashtable, object or primary string) into an ordered body table keyed by wire name.
    -PropertyMap translates PowerShell parameter names to wire names.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$InputObject,

        [Parameter()]
        [string]$PrimaryProperty,

        [Parameter()]
        [hashtable]$PropertyMap = @{}
    )

    $table = [ordered]@{}
    if ($null -eq $InputObject)
    {
        return $table
    }

    if ($InputObject -is [System.Collections.IDictionary])
    {
        foreach ($key in $InputObject.Keys)
        {
            $wire = if ($PropertyMap.ContainsKey([string]$key)) { $PropertyMap[[string]$key] } else { [string]$key }
            $table[$wire] = $InputObject[$key]
        }
    } elseif ($InputObject -is [string] -or $InputObject.GetType().IsValueType)
    {
        if (-not $PrimaryProperty)
        {
            throw "This command cannot accept a bare $($InputObject.GetType().Name) as -InputObject; pass a hashtable or object with request properties."
        }
        $table[$PrimaryProperty] = $InputObject
    } else
    {
        foreach ($property in $InputObject.PSObject.Properties)
        {
            if ($property.MemberType -in 'NoteProperty', 'Property', 'AliasProperty')
            {
                $wire = if ($PropertyMap.ContainsKey($property.Name)) { $PropertyMap[$property.Name] } else { $property.Name }
                $table[$wire] = $property.Value
            }
        }
    }
    $table
}

function Get-OpenApiHeaderValue
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$Headers,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $Headers)
    {
        return $null
    }
    foreach ($key in $Headers.Keys)
    {
        if ([string]$key -ieq $Name)
        {
            return [string]($Headers[$key] | Select-Object -First 1)
        }
    }
    $null
}

function Get-OpenApiResponseText
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [object]$Response
    )

    $content = $Response.Content
    if ($content -is [byte[]])
    {
        return [System.Text.Encoding]::UTF8.GetString($content)
    }
    if ($null -eq $content)
    {
        return ''
    }
    [string]$content
}

function Get-OpenApiResponseByte
{
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        [object]$Response
    )

    $stream = $Response.RawContentStream
    if ($stream -is [System.IO.MemoryStream])
    {
        return , $stream.ToArray()
    }
    if ($stream -is [System.IO.Stream])
    {
        $copy = [System.IO.MemoryStream]::new()
        $null = $stream.Seek(0, [System.IO.SeekOrigin]::Begin)
        $stream.CopyTo($copy)
        return , $copy.ToArray()
    }
    if ($Response.Content -is [byte[]])
    {
        return , $Response.Content
    }
    , [System.Text.Encoding]::UTF8.GetBytes((Get-OpenApiResponseText -Response $Response))
}

function Get-OpenApiErrorMessage
{
    <#
    .SYNOPSIS
    Extracts a readable message from an error response (FastAPI detail[], {message}, {error}, problem+json, or raw text).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [object]$Response
    )

    $text = Get-OpenApiResponseText -Response $Response
    if (-not $text)
    {
        return ''
    }

    $json = $null
    try
    {
        $json = $text | ConvertFrom-Json -AsHashtable -Depth 20 -ErrorAction Stop
    } catch
    {
        $json = $null
    }

    if ($json -is [System.Collections.IDictionary])
    {
        if ($json.Contains('detail'))
        {
            $detail = $json['detail']
            if ($detail -is [System.Collections.IDictionary])
            {
                foreach ($name in 'message', 'msg', 'error')
                {
                    if ($detail.Contains($name) -and $detail[$name])
                    {
                        return [string]$detail[$name]
                    }
                }
                return ConvertTo-Json -InputObject $detail -Compress -Depth 5
            }
            if ($detail -is [System.Collections.IEnumerable] -and $detail -isnot [string])
            {
                $parts = foreach ($item in $detail)
                {
                    if ($item -is [System.Collections.IDictionary] -and $item.Contains('msg'))
                    {
                        $location = if ($item.Contains('loc')) { (@($item['loc']) -join '.') + ': ' } else { '' }
                        "$location$($item['msg'])"
                    } else
                    {
                        [string]$item
                    }
                }
                return ($parts -join '; ')
            }
            if ($detail -is [System.Collections.IDictionary] -and $detail.Contains('message'))
            {
                return [string]$detail['message']
            }
            return [string]$detail
        }
        foreach ($name in 'message', 'error_description', 'error', 'title', 'errors')
        {
            if ($json.Contains($name) -and $json[$name])
            {
                $found = $json[$name]
                if ($found -is [System.Collections.IDictionary] -and $found.Contains('message'))
                {
                    return [string]$found['message']
                }
                if ($found -is [System.Collections.IEnumerable] -and $found -isnot [string])
                {
                    return (@($found | ForEach-Object { [string]$_ }) -join '; ')
                }
                return [string]$found
            }
        }
    }

    if ($text.Length -gt 500)
    {
        return $text.Substring(0, 500) + '...'
    }
    $text
}

function Invoke-OpenApiRequest
{
    <#
    .SYNOPSIS
    Sends one request on behalf of a generated OpenAPI client function.

    .DESCRIPTION
    Resolves the endpoint and credentials, builds the URI, headers and body, calls
    Invoke-WebRequest, then interprets the response by its actual Content-Type
    (OpenAPI documents frequently misdescribe binary endpoints as JSON):
    JSON is parsed, text is returned as a string, anything else is saved to
    -OutFile (or a temp file) and returned as a FileInfo carrying the response
    headers in a ResponseHeaders property. HEAD requests return [bool].

    .PARAMETER ClientInfo
    Hashtable emitted by the generator: ApiName, DefaultEndpoint, ServerUrl, BasePath,
    SecuritySchemes.

    .PARAMETER RawPathName
    Path parameters whose '/' characters are kept (catch-all routes such as /proxy/{path}).

    .PARAMETER Query
    Query parameters keyed by wire name. Arrays are repeated (explode) unless the name is in -CsvQueryName.

    .PARAMETER BodyType
    json, multipart (-Form) or form (urlencoded).

    .PARAMETER ResultType
    PSTypeName to stamp on JSON result objects.

    .OUTPUTS
    Parsed JSON, string, System.IO.FileInfo, bool or nothing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ClientInfo,

        [Parameter(Mandatory)]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$PathTemplate,

        [Parameter()]
        [hashtable]$PathParameter,

        [Parameter()]
        [string[]]$RawPathName,

        [Parameter()]
        [System.Collections.IDictionary]$Query,

        [Parameter()]
        [string[]]$CsvQueryName,

        [Parameter()]
        [System.Collections.IDictionary]$HeaderParameter,

        [Parameter()]
        [AllowNull()]
        [object]$Body,

        [Parameter()]
        [ValidateSet('json', 'multipart', 'form')]
        [string]$BodyType = 'json',

        [Parameter()]
        [string]$Endpoint,

        [Parameter()]
        [pscredential]$Credential,

        [Parameter()]
        [hashtable]$Headers,

        [Parameter()]
        [int]$TimeoutSec = 100,

        [Parameter()]
        [string]$OutFile,

        [Parameter()]
        [string]$ResultType
    )

    $base = Resolve-OpenApiEndpoint -ClientInfo $ClientInfo -Endpoint $Endpoint

    # --- path -------------------------------------------------------------
    $path = $PathTemplate
    foreach ($name in $(if ($PathParameter) { @($PathParameter.Keys) }))
    {
        $text = ConvertTo-OpenApiQueryValue -Value $PathParameter[$name]
        $escaped = if ($RawPathName -contains $name)
        {
            # Catch-all segment: escape each piece but keep the slashes.
            ($text -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
        } else
        {
            [uri]::EscapeDataString($text)
        }
        $path = $path.Replace("{$name}", $escaped)
    }

    # --- headers + auth ---------------------------------------------------
    $requestHeaders = @{}
    foreach ($name in $(if ($HeaderParameter) { @($HeaderParameter.Keys) }))
    {
        if ($null -ne $HeaderParameter[$name])
        {
            $requestHeaders[$name] = ConvertTo-OpenApiQueryValue -Value $HeaderParameter[$name]
        }
    }

    $queryTable = [ordered]@{}
    foreach ($name in $(if ($Query) { @($Query.Keys) }))
    {
        $queryTable[$name] = $Query[$name]
    }

    $secret = $Credential
    if (-not $secret)
    {
        $secret = $Script:OpenApiSessionCredential[$ClientInfo.ApiName]
    }
    $userName = $null
    $tokenValue = $null
    if ($secret)
    {
        $userName = $secret.UserName
        $tokenValue = $secret.GetNetworkCredential().Password
    }

    if ($tokenValue)
    {
        $scheme = @($ClientInfo.SecuritySchemes) | Select-Object -First 1
        $type = if ($scheme) { [string]$scheme.Type } else { 'http' }
        $flavour = if ($scheme -and $scheme.Scheme) { ([string]$scheme.Scheme).ToLowerInvariant() } else { 'basic' }

        switch -Regex ($type)
        {
            '^apiKey$'
            {
                switch ($scheme.In)
                {
                    'query' { $queryTable[$scheme.Name] = $tokenValue }
                    'cookie' { $requestHeaders['Cookie'] = '{0}={1}' -f $scheme.Name, $tokenValue }
                    default
                    {
                        # Swagger 2.0 has no bearer type, so swaggo/Go services declare "apiKey in header Authorization"
                        # and expect 'Bearer <token>'. A bare token gets the prefix; a value with a scheme is left alone.
                        $headerValue = $tokenValue
                        if ($scheme.Name -ieq 'Authorization' -and $headerValue -notmatch '\s')
                        {
                            $headerValue = "Bearer $headerValue"
                        } elseif ($scheme.Name -ine 'Authorization' -and $headerValue -match '^apikey\s+')
                        {
                            # Specs often say "Enter: apikey {your-token}" for a custom key header (a Swagger UI convention)
                            # while the service wants the bare token, so tolerate a pasted 'apikey ' prefix.
                            $headerValue = $headerValue -replace '^apikey\s+', ''
                        }
                        $requestHeaders[$scheme.Name] = $headerValue
                    }
                }
            }
            '^(oauth2|openIdConnect)$'
            {
                $requestHeaders['Authorization'] = "Bearer $tokenValue"
            }
            default
            {
                if ($flavour -eq 'basic')
                {
                    if ($userName)
                    {
                        $pair = [System.Text.Encoding]::UTF8.GetBytes("${userName}:$tokenValue")
                        $requestHeaders['Authorization'] = 'Basic ' + [Convert]::ToBase64String($pair)
                    } else
                    {
                        Write-Verbose 'Basic authentication needs a user name; ignoring secret-only credential.'
                    }
                } elseif ($flavour -eq 'bearer')
                {
                    $requestHeaders['Authorization'] = "Bearer $tokenValue"
                } else
                {
                    $requestHeaders['Authorization'] = "$flavour $tokenValue"
                }
            }
        }
    }

    if ($Headers)
    {
        foreach ($name in $Headers.Keys)
        {
            $requestHeaders[$name] = $Headers[$name]
        }
    }

    # --- query string -----------------------------------------------------
    $pairs = foreach ($name in $queryTable.Keys)
    {
        $value = $queryTable[$name]
        if ($null -eq $value)
        {
            continue
        }
        $encodedName = [uri]::EscapeDataString($name)
        if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string])
        {
            $items = @($value | ForEach-Object { ConvertTo-OpenApiQueryValue -Value $_ })
            if ($CsvQueryName -contains $name)
            {
                '{0}={1}' -f $encodedName, (($items | ForEach-Object { [uri]::EscapeDataString($_) }) -join ',')
            } else
            {
                foreach ($item in $items)
                {
                    '{0}={1}' -f $encodedName, [uri]::EscapeDataString($item)
                }
            }
        } else
        {
            '{0}={1}' -f $encodedName, [uri]::EscapeDataString((ConvertTo-OpenApiQueryValue -Value $value))
        }
    }

    $uri = $base + $path
    if ($pairs)
    {
        $uri += '?' + (@($pairs) -join '&')
    }

    # --- request ----------------------------------------------------------
    $request = @{
        Uri                = $uri
        Method             = $Method.ToUpperInvariant()
        TimeoutSec         = $TimeoutSec
        SkipHttpErrorCheck = $true
        ErrorAction        = 'Stop'
    }
    if ($requestHeaders.Count -gt 0)
    {
        $request.Headers = $requestHeaders
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body)
    {
        switch ($BodyType)
        {
            'json'
            {
                $request.Body = ConvertTo-Json -InputObject $Body -Depth 20 -Compress
                $request.ContentType = 'application/json'
            }
            'multipart'
            {
                $form = [ordered]@{}
                foreach ($key in $Body.Keys)
                {
                    $value = $Body[$key]
                    $form[$key] = if ($value -is [System.IO.FileSystemInfo] -or $value -is [string]) { $value } else { ConvertTo-OpenApiQueryValue -Value $value }
                }
                $request.Form = $form
            }
            'form'
            {
                $form = [ordered]@{}
                foreach ($key in $Body.Keys)
                {
                    $form[$key] = ConvertTo-OpenApiQueryValue -Value $Body[$key]
                }
                $request.Body = $form
                $request.ContentType = 'application/x-www-form-urlencoded'
            }
        }
    }

    Write-Verbose "$($request.Method) $uri"
    try
    {
        $response = Invoke-WebRequest @request
    } catch
    {
        throw "API call failed: $($request.Method) $uri - $($_.Exception.Message)"
    }

    $status = [int]$response.StatusCode
    if ($request.Method -eq 'HEAD')
    {
        if ($status -ge 200 -and $status -lt 300)
        {
            return $true
        }
        if ($status -eq 404)
        {
            return $false
        }
    }
    if ($status -ge 400)
    {
        $message = Get-OpenApiErrorMessage -Response $response
        $suffix = if ($message) { " - $message" } else { '' }
        throw "API call failed: $($request.Method) $uri - HTTP $status$suffix"
    }
    if ($request.Method -eq 'HEAD')
    {
        return $true
    }

    # --- response ---------------------------------------------------------
    $contentType = Get-OpenApiHeaderValue -Headers $response.Headers -Name 'Content-Type'
    $mediaType = if ($contentType) { ($contentType -split ';')[0].Trim().ToLowerInvariant() } else { '' }
    $isJson = $mediaType -match 'json'
    $isText = $isJson -or $mediaType -like 'text/*' -or $mediaType -match 'xml' -or -not $mediaType

    if ($OutFile -or -not $isText)
    {
        $bytes = Get-OpenApiResponseByte -Response $response
        if ($status -eq 204 -or $bytes.Length -eq 0)
        {
            return
        }

        if ($OutFile)
        {
            $target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
            if (Test-Path -LiteralPath $target -PathType Container)
            {
                $disposition = Get-OpenApiHeaderValue -Headers $response.Headers -Name 'Content-Disposition'
                $leaf = if ($disposition -match 'filename\*?=(?:UTF-8'''')?"?([^";]+)"?')
                {
                    [IO.Path]::GetFileName($Matches[1])
                } else
                {
                    $null
                }
                if (-not $leaf)
                {
                    $leaf = 'response' + $(if ($Script:OpenApiMimeExtension.ContainsKey($mediaType)) { $Script:OpenApiMimeExtension[$mediaType] } else { '.bin' })
                }
                $target = Join-Path -Path $target -ChildPath $leaf
            }
        } else
        {
            $extension = if ($Script:OpenApiMimeExtension.ContainsKey($mediaType)) { $Script:OpenApiMimeExtension[$mediaType] } else { '.bin' }
            $leaf = '{0}_{1:yyyyMMdd_HHmmss_fff}{2}' -f $ClientInfo.ApiName, [datetime]::Now, $extension
            $target = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath $leaf
        }

        $directory = Split-Path -Path $target -Parent
        if ($directory -and -not (Test-Path -LiteralPath $directory))
        {
            $null = New-Item -ItemType Directory -Path $directory -Force
        }
        [System.IO.File]::WriteAllBytes($target, $bytes)

        $responseHeaders = [ordered]@{}
        foreach ($key in $response.Headers.Keys)
        {
            $responseHeaders[[string]$key] = (@($response.Headers[$key]) -join ', ')
        }
        return Get-Item -LiteralPath $target | Add-Member -NotePropertyName ResponseHeaders -NotePropertyValue $responseHeaders -PassThru
    }

    $text = Get-OpenApiResponseText -Response $response
    if (-not $text -or $status -eq 204)
    {
        return
    }
    if (-not $isJson)
    {
        return $text
    }

    $result = $text | ConvertFrom-Json -Depth 20
    if ($ResultType)
    {
        foreach ($item in @($result))
        {
            if ($item -is [pscustomobject])
            {
                $item.PSObject.TypeNames.Insert(0, $ResultType)
            }
        }
    }
    $result
}
