# Folds a spec that is split over several files (external $ref such as './schemas/x.yaml#/components/schemas/X')
# into one self-contained document, so the rest of the generator only ever sees local '#/components/...' references.

function Merge-OpenApiExternalReference
{
    <#
    .SYNOPSIS
    Replaces external $ref entries with local ones by copying the referenced objects into the document's components.

    .DESCRIPTION
    Targets that live under '#/components/<kind>/<name>' in their own file keep that kind and name. A reference to a
    whole file is filed under the kind its position implies (parameter, response, request body, header or schema) and
    named after the file; anywhere else the target is copied in place. Name clashes between different targets get a
    numeric suffix. Relative paths resolve against the file that holds the reference and work for local files and
    http(s) URLs. Examples are not followed. The document is modified in place.

    .PARAMETER Document
    The root document (3.x).

    .PARAMETER Location
    Full path or URL the root document was read from.

    .PARAMETER RootSha256
    Hash of the root document's bytes.

    .OUTPUTS
    PSCustomObject with Sha256 (the root hash when nothing external was read, otherwise a hash over every file read)
    and Files (the relative names of the external files read).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Document,

        [Parameter(Mandatory)]
        [string]$Location,

        [Parameter(Mandatory)]
        [string]$RootSha256
    )

    $rootKey = Get-OpenApiLocationKey -Location $Location
    $context = @{
        Root      = $Document
        RootKey   = $rootKey
        Locations = @{ $rootKey = $Location }
        Documents = @{ $rootKey = $Document }
        Hashes    = @{}
        Hoisted   = @{}
        Active    = [System.Collections.Generic.HashSet[string]]::new()
    }

    Convert-OpenApiExternalNode -Context $context -Node $Document -DocumentKey $rootKey -Hint 'root'

    if ($context.Hashes.Count -eq 0)
    {
        return [pscustomobject]@{ Sha256 = $RootSha256; Files = @() }
    }

    $rootName = if ($Location -match '^https?://') { $Location } else { Split-Path -Path $Location -Leaf }
    $entries = [System.Collections.Generic.List[string]]::new()
    $entries.Add("$rootName $RootSha256")
    foreach ($name in $context.Hashes.Keys)
    {
        $entries.Add("$name $($context.Hashes[$name])")
    }
    $combined = [System.Text.Encoding]::UTF8.GetBytes((@($entries | Sort-Object { $_ }) -join "`n"))
    $sha = [System.Security.Cryptography.SHA256]::HashData($combined)
    [pscustomobject]@{
        Sha256 = [System.BitConverter]::ToString($sha).Replace('-', '').ToLowerInvariant()
        Files  = @($context.Hashes.Keys | Sort-Object)
    }
}

function Get-OpenApiLocationKey
{
    # One canonical string per file or URL so a file reached by two relative routes is read once.
    param([string]$Location)

    if ($Location -match '^https?://')
    {
        $builder = [System.UriBuilder]::new($Location)
        $builder.Fragment = ''
        return $builder.Uri.AbsoluteUri
    }
    [System.IO.Path]::GetFullPath($Location)
}

function Resolve-OpenApiExternalLocation
{
    param([string]$BaseLocation, [string]$Relative)

    if ($Relative -match '^https?://')
    {
        return $Relative
    }
    if ($BaseLocation -match '^https?://')
    {
        return [uri]::new([uri]$BaseLocation, $Relative).AbsoluteUri
    }
    $baseDirectory = Split-Path -Path $BaseLocation -Parent
    $localRelative = [uri]::UnescapeDataString($Relative).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($baseDirectory, $localRelative))
}

function Copy-OpenApiNode
{
    # Deep copy of a parsed document node.
    param($Node)

    if ($Node -is [System.Collections.IDictionary])
    {
        $copy = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
        foreach ($key in $Node.Keys)
        {
            $copy[[string]$key] = Copy-OpenApiNode -Node $Node[$key]
        }
        return $copy
    }
    if ($Node -is [System.Collections.IList])
    {
        $items = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $Node)
        {
            $items.Add((Copy-OpenApiNode -Node $item))
        }
        return , $items.ToArray()
    }
    $Node
}

function ConvertTo-OpenApiComponentName
{
    # './get_product_by_barcode.yaml' -> 'GetProductByBarcode'
    param([string]$File)

    $base = [System.IO.Path]::GetFileNameWithoutExtension(($File -replace '\?.*$', '').TrimEnd('/'))
    $parts = @($base -split '[^A-Za-z0-9]+' | Where-Object { $_ } | ForEach-Object { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1) })
    if ($parts.Count -eq 0)
    {
        return 'External'
    }
    -join $parts
}

function Convert-OpenApiExternalNode
{
    # Walks a node and rewrites every external $ref. $Hint says what kind of object the node is, which decides
    # where a reference to a whole file gets filed.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Context,

        [Parameter()]
        $Node,

        [Parameter(Mandatory)]
        [string]$DocumentKey,

        [Parameter()]
        [string]$Hint = 'inline'
    )

    if ($Node -is [System.Collections.IList])
    {
        foreach ($item in @($Node))
        {
            Convert-OpenApiExternalNode -Context $Context -Node $item -DocumentKey $DocumentKey -Hint $Hint
        }
        return
    }
    if ($Node -isnot [System.Collections.IDictionary])
    {
        return
    }

    if ($Node.Contains('$ref') -and $Node['$ref'] -is [string])
    {
        Convert-OpenApiExternalReference -Context $Context -Node $Node -DocumentKey $DocumentKey -Hint $Hint
        return
    }

    foreach ($key in @($Node.Keys))
    {
        $value = $Node[$key]
        if ($value -isnot [System.Collections.IDictionary] -and $value -isnot [System.Collections.IList])
        {
            continue
        }
        switch -CaseSensitive ($key)
        {
            { $_ -in 'example', 'examples' } { }
            { $_ -in 'properties', 'patternProperties', 'definitions', '$defs', 'dependentSchemas', 'schemas' }
            {
                if ($value -is [System.Collections.IDictionary])
                {
                    foreach ($child in @($value.Keys))
                    {
                        Convert-OpenApiExternalNode -Context $Context -Node $value[$child] -DocumentKey $DocumentKey -Hint 'schemas'
                    }
                }
            }
            { $_ -in 'schema', 'items', 'additionalProperties', 'not', 'contains', 'propertyNames', 'unevaluatedProperties', 'unevaluatedItems', 'if', 'then', 'else', 'allOf', 'anyOf', 'oneOf', 'prefixItems' }
            {
                Convert-OpenApiExternalNode -Context $Context -Node $value -DocumentKey $DocumentKey -Hint 'schemas'
            }
            'parameters'
            {
                if ($value -is [System.Collections.IDictionary])
                {
                    foreach ($child in @($value.Keys))
                    {
                        Convert-OpenApiExternalNode -Context $Context -Node $value[$child] -DocumentKey $DocumentKey -Hint 'parameters'
                    }
                } else
                {
                    Convert-OpenApiExternalNode -Context $Context -Node $value -DocumentKey $DocumentKey -Hint 'parameters'
                }
            }
            'requestBody' { Convert-OpenApiExternalNode -Context $Context -Node $value -DocumentKey $DocumentKey -Hint 'requestBodies' }
            { $_ -in 'requestBodies', 'responses', 'headers', 'content', 'paths' }
            {
                $childHint = @{ requestBodies = 'requestBodies'; responses = 'responses'; headers = 'headers'; content = 'media'; paths = 'pathItem' }[$key]
                if ($value -is [System.Collections.IDictionary])
                {
                    foreach ($child in @($value.Keys))
                    {
                        Convert-OpenApiExternalNode -Context $Context -Node $value[$child] -DocumentKey $DocumentKey -Hint $childHint
                    }
                }
            }
            default
            {
                Convert-OpenApiExternalNode -Context $Context -Node $value -DocumentKey $DocumentKey -Hint 'inline'
            }
        }
    }
}

function Convert-OpenApiExternalReference
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Context,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Node,

        [Parameter(Mandatory)]
        [string]$DocumentKey,

        [Parameter(Mandatory)]
        [string]$Hint
    )

    $reference = [string]$Node['$ref']
    $hash = $reference.IndexOf('#')
    $file = if ($hash -ge 0) { $reference.Substring(0, $hash) } else { $reference }
    $pointer = if ($hash -ge 0) { $reference.Substring($hash + 1) } else { '' }
    if ($pointer -eq '/')
    {
        $pointer = ''
    }

    if ($file -eq '' -and $DocumentKey -eq $Context.RootKey)
    {
        return
    }

    $targetLocation = if ($file -eq '') { $Context.Locations[$DocumentKey] } else { Resolve-OpenApiExternalLocation -BaseLocation $Context.Locations[$DocumentKey] -Relative $file }
    $targetKey = Get-OpenApiLocationKey -Location $targetLocation

    if ($targetKey -eq $Context.RootKey)
    {
        if ($pointer -eq '')
        {
            throw "'$reference' points back at the whole root document, which cannot be merged."
        }
        $Node['$ref'] = "#$pointer"
        return
    }

    if (-not $Context.Documents.ContainsKey($targetKey))
    {
        try
        {
            $loaded = Read-OpenApiSource -Location $targetLocation
        } catch
        {
            throw "$($_.Exception.Message) (referenced as '$reference')"
        }
        $Context.Documents[$targetKey] = $loaded.Document
        $Context.Locations[$targetKey] = $targetLocation
        $rootLocation = $Context.Locations[$Context.RootKey]
        $relativeName = if ($targetLocation -match '^https?://' -or $rootLocation -match '^https?://')
        {
            $targetLocation
        } else
        {
            [System.IO.Path]::GetRelativePath((Split-Path -Path $rootLocation -Parent), $targetLocation).Replace('\', '/')
        }
        $Context.Hashes[$relativeName] = $loaded.Sha256
    }
    $targetDocument = $Context.Documents[$targetKey]
    $target = if ($pointer -eq '') { $targetDocument } else { Resolve-OpenApiReference -Document $targetDocument -Reference "#$pointer" }

    $kind = $null
    $name = $null
    if ($pointer -match '^/components/(?<kind>[^/]+)/(?<name>[^/]+)$')
    {
        $kind = $Matches['kind']
        $name = [uri]::UnescapeDataString($Matches['name']).Replace('~1', '/').Replace('~0', '~')
    } elseif ($Hint -in 'schemas', 'parameters', 'responses', 'requestBodies', 'headers')
    {
        $kind = $Hint
        $name = if ($pointer -eq '') { ConvertTo-OpenApiComponentName -File $file } else { ConvertTo-OpenApiComponentName -File ($pointer.Split('/')[-1]) }
    }

    $id = "$targetKey#$pointer|$kind"
    if ($kind)
    {
        if (-not $Context.Hoisted.ContainsKey($id))
        {
            $root = $Context.Root
            if (-not $root['components'])
            {
                $root['components'] = [ordered]@{}
            }
            if (-not $root['components'][$kind])
            {
                $root['components'][$kind] = [ordered]@{}
            }
            $unique = $name
            $suffix = 2
            while ($root['components'][$kind].Contains($unique))
            {
                $unique = "$name$suffix"
                $suffix++
            }
            $Context.Hoisted[$id] = $unique
            $copy = Copy-OpenApiNode -Node $target
            $root['components'][$kind][$unique] = $copy
            $kindHint = if ($kind -in 'schemas', 'parameters', 'responses', 'requestBodies', 'headers') { $kind } else { 'inline' }
            Convert-OpenApiExternalNode -Context $Context -Node $copy -DocumentKey $targetKey -Hint $kindHint
        }
        $Node['$ref'] = "#/components/$kind/$($Context.Hoisted[$id])"
        return
    }

    # No sensible home in components: copy the target where the reference was.
    if (-not $Context.Active.Add($id))
    {
        throw "Circular external reference through '$reference'."
    }
    try
    {
        $copy = Copy-OpenApiNode -Node $target
        Convert-OpenApiExternalNode -Context $Context -Node $copy -DocumentKey $targetKey -Hint $Hint
    } finally
    {
        $null = $Context.Active.Remove($id)
    }
    $null = $Node.Remove('$ref')
    if ($copy -is [System.Collections.IDictionary])
    {
        foreach ($key in $copy.Keys)
        {
            if (-not $Node.Contains($key))
            {
                $Node[$key] = $copy[$key]
            }
        }
    }
}
