# Name derivation for New-OpenApiClient: HTTP operation -> Verb-Noun, wire names -> PowerShell parameter names.

$Script:OpenApiVerbSynonym = @{
    create     = 'New'
    new        = 'New'
    make       = 'New'
    generate   = 'New'
    build      = 'New'
    add        = 'Add'
    list       = 'Get'
    get        = 'Get'
    retrieve   = 'Get'
    fetch      = 'Get'
    read       = 'Get'
    show       = 'Get'
    view       = 'Get'
    lookup     = 'Get'
    load       = 'Get'
    serve      = 'Get'
    find       = 'Find'
    search     = 'Search'
    query      = 'Search'
    update     = 'Update'
    modify     = 'Update'
    edit       = 'Update'
    patch      = 'Update'
    reload     = 'Update'
    refresh    = 'Update'
    put        = 'Set'
    replace    = 'Set'
    set        = 'Set'
    delete     = 'Remove'
    remove     = 'Remove'
    destroy    = 'Remove'
    drop       = 'Remove'
    clear      = 'Clear'
    download   = 'Save'
    upload     = 'Send'
    send       = 'Send'
    combine    = 'Join'
    merge      = 'Merge'
    check      = 'Test'
    test       = 'Test'
    verify     = 'Test'
    validate   = 'Test'
    ping       = 'Test'
    unload     = 'Unregister'
    register   = 'Register'
    unregister = 'Unregister'
    tune       = 'Optimize'
    translate  = 'ConvertTo'
    convert    = 'ConvertTo'
    run        = 'Invoke'
    execute    = 'Invoke'
    invoke     = 'Invoke'
    start      = 'Start'
    stop       = 'Stop'
    cancel     = 'Stop'
    restart    = 'Restart'
    enable     = 'Enable'
    disable    = 'Disable'
    export     = 'Export'
    import     = 'Import'
    copy       = 'Copy'
    move       = 'Move'
    rename     = 'Rename'
    submit     = 'Submit'
    approve    = 'Approve'
    force      = 'Invoke'
    trigger    = 'Invoke'
    readmit    = 'Restore'
    reinstate  = 'Restore'
    restore    = 'Restore'
    revoke     = 'Revoke'
}

$Script:OpenApiMethodWord = 'get', 'post', 'put', 'patch', 'delete', 'head', 'options'

$Script:OpenApiTestWord = 'check', 'test', 'ping', 'verify', 'validate', 'exists', 'exist'

$Script:OpenApiMethodVerb = @{
    GET     = 'Get'
    POST    = 'New'
    PUT     = 'Set'
    PATCH   = 'Update'
    DELETE  = 'Remove'
    HEAD    = 'Test'
    OPTIONS = 'Get'
    TRACE   = 'Get'
}

# Names that would shadow automatic variables / common parameters, or that generated functions already define.
$Script:OpenApiReservedParameter = @(
    'Input', 'Args', 'Error', 'Host', 'Home', 'This', 'PSItem', 'Matches', 'Null', 'True', 'False', 'PID', 'PWD',
    'Event', 'EventArgs', 'Sender', 'Profile', 'ShellId', 'StackTrace', 'ExecutionContext', 'PSCmdlet', 'MyInvocation',
    'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ProgressAction',
    'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable',
    'WhatIf', 'Confirm',
    'Endpoint', 'Credential', 'Headers', 'TimeoutSec', 'OutFile', 'InputObject'
)

# Parameters every generated function already has (or PowerShell adds); wire-name aliases must not shadow them.
$Script:OpenApiCommonParameter = @(
    'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ProgressAction',
    'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable',
    'WhatIf', 'Confirm', 'Endpoint', 'Credential', 'Headers', 'TimeoutSec', 'OutFile', 'InputObject'
)

function Split-OpenApiWord
{
    <#
    .SYNOPSIS
    Splits text on separators and camelCase boundaries: 'filter.zipCode.near' -> filter, zip, Code, near.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    $spaced = $Text -creplace '(?<=[a-z0-9])(?=[A-Z])', ' ' -creplace '(?<=[A-Z])(?=[A-Z][a-z])', ' '
    $spaced -split '[^A-Za-z0-9]+' | Where-Object { $_ }
}

function ConvertTo-OpenApiPascalCase
{
    <#
    .SYNOPSIS
    Title-cases each word and joins them ('x-raw-response' -> XRawResponse, 'SSML' -> Ssml).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Word
    )

    $parts = foreach ($item in $Word)
    {
        if (-not $item)
        {
            continue
        }
        $item.Substring(0, 1).ToUpperInvariant() + $item.Substring(1).ToLowerInvariant()
    }
    -join $parts
}

function Get-OpenApiSingularWord
{
    <#
    .SYNOPSIS
    Naive singulariser for the last word of a noun phrase (PowerShell nouns are singular by convention).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Word
    )

    $lower = $Word.ToLowerInvariant()
    if ($lower.Length -le 3 -or $lower -match '(ss|us|is|ics|news|series|species|alias|canvas|atlas|bias|gas|lens|status)$')
    {
        return $Word
    }
    if ($lower -match '[^aeiou]ies$')
    {
        return $Word.Substring(0, $Word.Length - 3) + 'y'
    }
    if ($lower -match '(sses|xes|zes|ches|shes)$')
    {
        return $Word.Substring(0, $Word.Length - 2)
    }
    if ($lower.EndsWith('s'))
    {
        return $Word.Substring(0, $Word.Length - 1)
    }
    $Word
}

function Get-OpenApiApprovedVerb
{
    <#
    .SYNOPSIS
    Returns the canonical casing of an approved verb, or $null when the word is not one.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Word
    )

    if (-not $Script:OpenApiApprovedVerb)
    {
        $Script:OpenApiApprovedVerb = @{}
        foreach ($entry in Get-Verb)
        {
            $Script:OpenApiApprovedVerb[$entry.Verb] = $entry.Verb
        }
    }
    $Script:OpenApiApprovedVerb[$Word]
}

function Get-OpenApiOperationTextCandidate
{
    <#
    .SYNOPSIS
    Lists the texts an operation can be named from, best guess first: summary, cleaned operationId, path.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Method,

        [Parameter()]
        [string]$Summary,

        [Parameter()]
        [string]$OperationId
    )

    if ($Summary -and $Summary.Trim())
    {
        $Summary.Trim()
    }

    if ($OperationId)
    {
        $id = $OperationId
        # FastAPI appends '<path with non-alphanumerics as underscores>_<method>' to the function name.
        $lowerId = $id.ToLowerInvariant()
        $methodSuffix = '_' + $Method.ToLowerInvariant()
        if ($lowerId.EndsWith($methodSuffix))
        {
            $stripped = $lowerId.Substring(0, $lowerId.Length - $methodSuffix.Length)
            $slug = $Path.ToLowerInvariant() -replace '[^a-z0-9]', '_'
            if ($slug.Length -gt 1 -and $stripped.EndsWith($slug) -and $stripped.Length -gt $slug.Length)
            {
                $id = $stripped.Substring(0, $stripped.Length - $slug.Length)
            }
        }
        $id
    }

    if (-not $Summary -and -not $OperationId)
    {
        $segments = $Path.Split('/') | Where-Object { $_ -and $_ -notmatch '^\{' }
        "$($Method.ToLowerInvariant()) $($segments -join ' ')"
    }
}

function Resolve-OpenApiVerbWord
{
    <#
    .SYNOPSIS
    Finds the verb in a list of words and scores how trustworthy the match is.

    .DESCRIPTION
    Score 3: the first word is a known verb/synonym. Score 2: a test-ish word anywhere
    ('Health Check', 'ChainExists'). Score 1: a synonym later in the text ('LocationsGetByID'),
    with any trailing 'By ...' clause dropped. Score 0: nothing recognised.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Word,

        [Parameter()]
        [hashtable]$VerbMap = @{}
    )

    $result = [pscustomobject]@{ Verb = $null; NounWords = @($Word); Score = 0 }
    if ($Word.Count -eq 0)
    {
        return $result
    }

    $lead = $Word[0].ToLowerInvariant()
    $leadVerb = if ($VerbMap.ContainsKey($lead)) { $VerbMap[$lead] }
    elseif ($Script:OpenApiVerbSynonym.ContainsKey($lead)) { $Script:OpenApiVerbSynonym[$lead] }
    else { Get-OpenApiApprovedVerb -Word $Word[0] }
    if ($leadVerb)
    {
        $result.Verb = $leadVerb
        $result.NounWords = @($Word | Select-Object -Skip 1)
        $result.Score = 3
        return $result
    }

    $testIndex = -1
    for ($i = 0; $i -lt $Word.Count; $i++)
    {
        if ($Word[$i].ToLowerInvariant() -in $Script:OpenApiTestWord)
        {
            $testIndex = $i
            break
        }
    }
    if ($testIndex -ge 0)
    {
        $result.Verb = 'Test'
        $result.NounWords = @(for ($i = 0; $i -lt $Word.Count; $i++) { if ($i -ne $testIndex) { $Word[$i] } })
        $result.Score = 2
        return $result
    }

    # The last word is excluded: ids such as 'BulkAssignAsyncPut' end in an echo of the HTTP method, not a verb.
    for ($i = 1; $i -lt $Word.Count - 1; $i++)
    {
        $candidate = $Word[$i].ToLowerInvariant()
        $mapped = if ($VerbMap.ContainsKey($candidate)) { $VerbMap[$candidate] } elseif ($Script:OpenApiVerbSynonym.ContainsKey($candidate)) { $Script:OpenApiVerbSynonym[$candidate] }
        if ($mapped)
        {
            $before = @($Word | Select-Object -First $i)
            $after = @($Word | Select-Object -Skip ($i + 1))
            for ($j = 0; $j -lt $after.Count; $j++)
            {
                if ($after[$j].ToLowerInvariant() -eq 'by')
                {
                    $after = @($after | Select-Object -First $j)
                    break
                }
            }
            $result.Verb = $mapped
            $result.NounWords = @($before) + @($after)
            $result.Score = 1
            return $result
        }
    }
    $result
}

function Get-OpenApiPathVerbNoun
{
    <#
    .SYNOPSIS
    Names an operation from its route alone (ASP.NET Core/Swashbuckle output has no summary or operationId).

    .DESCRIPTION
    Path segments become the noun, singular ('api' and version segments such as 'v1' are dropped, path
    parameters ignored). A trailing action segment names the verb ('/devices/search' -> Search-Device);
    otherwise the HTTP method does (GET Get, POST New, PUT Set, PATCH Update, DELETE Remove, HEAD Test).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Method,

        [Parameter()]
        [hashtable]$VerbMap = @{}
    )

    $words = @($Path.Split('/') |
            Where-Object { $_ -and $_ -notmatch '^\{' -and $_ -ne 'api' -and $_ -notmatch '^v\d+(\.\d+)*$' } |
            ForEach-Object { Split-OpenApiWord -Text $_ })

    $verb = $null
    if ($words.Count -gt 0)
    {
        $last = $words[-1].ToLowerInvariant()
        $mapped = if ($VerbMap.ContainsKey($last)) { $VerbMap[$last] } elseif ($Script:OpenApiVerbSynonym.ContainsKey($last)) { $Script:OpenApiVerbSynonym[$last] }
        if ($mapped)
        {
            $verb = $mapped
            $words = @($words | Select-Object -SkipLast 1)
        }
    }
    if (-not $verb)
    {
        $verb = $Script:OpenApiMethodVerb[$Method]
    }
    if ($words.Count -eq 0)
    {
        $words = @('Item')
    }

    [pscustomobject]@{
        Verb = $verb
        Noun = ConvertTo-OpenApiPascalCase -Word @($words | ForEach-Object { Get-OpenApiSingularWord -Word $_ })
    }
}

function Get-OpenApiVerbNoun
{
    <#
    .SYNOPSIS
    Derives an approved Verb and a (prefix-less, singular) Noun for one operation.

    .DESCRIPTION
    Each naming candidate (summary, operationId, path) is scored by Resolve-OpenApiVerbWord and
    the best wins, summary first on ties. With no verb found the HTTP method decides
    (POST/PUT/PATCH with words become Invoke- and keep every word in the noun).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Method,

        [Parameter()]
        [string]$Summary,

        [Parameter()]
        [string]$OperationId,

        [Parameter()]
        [hashtable]$VerbMap = @{}
    )

    if (-not ($Summary -and $Summary.Trim()) -and -not $OperationId)
    {
        return Get-OpenApiPathVerbNoun -Path $Path -Method $Method -VerbMap $VerbMap
    }

    $best = $null
    $firstWords = $null
    foreach ($text in Get-OpenApiOperationTextCandidate -Path $Path -Method $Method -Summary $Summary -OperationId $OperationId)
    {
        $words = @(Split-OpenApiWord -Text $text)
        # Method-style ids ('PostBulkAssignAsyncPut', 'GetSearchdeviceByDeviceid') lead with the HTTP method. That word
        # is not part of the resource name; the method itself picks the verb unless a real verb follows.
        $methodStyle = $text -ne $Summary.Trim() -and $words.Count -gt 1 -and $words[0].ToLowerInvariant() -in $Script:OpenApiMethodWord
        if ($methodStyle)
        {
            $words = @($words | Select-Object -Skip 1)
        }
        if (-not $firstWords)
        {
            $firstWords = $words
        }
        $resolved = Resolve-OpenApiVerbWord -Word $words -VerbMap $VerbMap
        if ($methodStyle -and $resolved.Score -lt 3)
        {
            $resolved.NounWords = $words
            $resolved.Verb = if ($Method -eq 'POST') { 'Invoke' } else { $Script:OpenApiMethodVerb[$Method] }
            $resolved.Score = 2
        }
        if ($null -eq $best -or $resolved.Score -gt $best.Score)
        {
            $best = $resolved
        }
    }

    $verb = $best.Verb
    $nounWords = @($best.NounWords)
    for ($i = 1; $i -lt $nounWords.Count; $i++)
    {
        # 'Location By Id' names the resource, not the lookup key.
        if ($nounWords[$i].ToLowerInvariant() -eq 'by')
        {
            $nounWords = @($nounWords | Select-Object -First $i)
            break
        }
    }
    if ($nounWords.Count -gt 0 -and $nounWords[0].ToLowerInvariant() -eq 'by')
    {
        # 'Reset By Deviceid' (path /{deviceId}/reset): the thing acted on is what the key identifies.
        $keyWords = @()
        if ($Path -match '\{([^}/]+)\}')
        {
            $keyWords = @(Split-OpenApiWord -Text $Matches[1] | Where-Object { $_.ToLowerInvariant() -notin 'id', 'identifier', 'key' })
        }
        $nounWords = if ($keyWords.Count -gt 0) { $keyWords } else { @('Item') }
    }
    $preposition = 'to', 'from', 'in', 'into', 'for', 'of', 'on', 'with', 'at'
    for ($i = 1; $i -lt $nounWords.Count; $i++)
    {
        # 'Add devices to inventory' / 'Remove device from inventory' name the device, not where it goes.
        if ($nounWords[$i].ToLowerInvariant() -in $preposition)
        {
            $nounWords = @($nounWords | Select-Object -First $i)
            break
        }
    }
    if (-not $verb)
    {
        $nounWords = @($firstWords)
        $verb = if (($Method -in 'POST', 'PUT', 'PATCH') -and $nounWords.Count -gt 0) { 'Invoke' } else { $Script:OpenApiMethodVerb[$Method] }
    }

    if ($nounWords.Count -eq 0)
    {
        $nounWords = @($Path.Split('/') | Where-Object { $_ -and $_ -notmatch '^\{' } | Select-Object -Last 1 | ForEach-Object { Split-OpenApiWord -Text $_ })
        if ($nounWords.Count -eq 0)
        {
            $nounWords = @('Item')
        }
    }

    # Drop determiners/fillers: 'List all pets' -> Pet, 'Create a pet' -> Pet.
    $filler = 'a', 'an', 'the', 'all', 'any', 'every', 'specific', 'given'
    $kept = @($nounWords | Where-Object { $_.ToLowerInvariant() -notin $filler })
    if ($kept.Count -gt 0)
    {
        $nounWords = $kept
    }

    $nounWords[-1] = Get-OpenApiSingularWord -Word $nounWords[-1]

    [pscustomobject]@{
        Verb = $verb
        Noun = ConvertTo-OpenApiPascalCase -Word $nounWords
    }
}

function Resolve-OpenApiFunctionName
{
    <#
    .SYNOPSIS
    Assigns a unique Verb-PrefixNoun function name to every operation record.

    .DESCRIPTION
    Duplicates are resolved deterministically: the record whose path ends in a path parameter gets
    'ById', then the HTTP method name, then a number. -NameOverride (keyed by operationId or 'METHOD /path')
    wins over everything.

    .PARAMETER Operation
    Records with Path, Method, Summary, OperationId.

    .OUTPUTS
    The same records with Name, Verb and Noun properties added.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Operation,

        [Parameter(Mandatory)]
        [string]$Prefix,

        [Parameter()]
        [hashtable]$VerbMap = @{},

        [Parameter()]
        [hashtable]$NameOverride = @{},

        [Parameter()]
        [string[]]$ReservedName = @()
    )

    $used = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $ReservedName)
    {
        $null = $used.Add($name)
    }

    $drafts = foreach ($item in $Operation)
    {
        $override = $null
        foreach ($key in $item.OperationId, "$($item.Method) $($item.Path)")
        {
            if ($key -and $NameOverride.ContainsKey($key))
            {
                $override = [string]$NameOverride[$key]
            }
        }

        $parts = Get-OpenApiVerbNoun -Path $item.Path -Method $item.Method -Summary $item.Summary -OperationId $item.OperationId -VerbMap $VerbMap
        [pscustomobject]@{
            Record        = $item
            Verb          = $parts.Verb
            Noun          = $Prefix + $parts.Noun
            Override      = $override
            EndsWithParam = ($item.Path -match '\}/?$')
            LastParameter = if ($item.Path -match '\{([^}/]+)\}/?$') { $Matches[1] } else { $null }
        }
    }

    # Overrides first so they always get the name they asked for.
    foreach ($draft in $drafts | Where-Object Override)
    {
        if (-not $used.Add($draft.Override))
        {
            throw "NameOverride '$($draft.Override)' collides with another function name."
        }
        $draft.Record | Add-Member -NotePropertyName Name -NotePropertyValue $draft.Override -Force
        $draft.Record | Add-Member -NotePropertyName Verb -NotePropertyValue ($draft.Override -split '-')[0] -Force
        $draft.Record | Add-Member -NotePropertyName Noun -NotePropertyValue ($draft.Override -split '-', 2)[1] -Force
    }

    $ordered = $drafts | Where-Object { -not $_.Override } | Sort-Object -Property @{ Expression = { $_.EndsWithParam } }, @{ Expression = { $_.Record.Path } }, @{ Expression = { $_.Record.Method } }
    foreach ($draft in $ordered)
    {
        $candidates = [System.Collections.Generic.List[string]]::new()
        $candidates.Add("$($draft.Verb)-$($draft.Noun)")
        if ($draft.EndsWithParam)
        {
            # '/models/{model}' and '/things/{thingId}' are plain lookups ById; '/programs/{a}/{b}/{hostname}' is By<Key>.
            $parameterWords = @(Split-OpenApiWord -Text $draft.LastParameter)
            $lastNounWord = ($draft.Noun -csplit '(?=[A-Z])' | Where-Object { $_ })[-1]
            $isIdLike = $parameterWords[-1] -ieq 'id' -or ($parameterWords -join '') -ieq $lastNounWord -or ($parameterWords -join '') -ieq (Get-OpenApiSingularWord -Word $lastNounWord)
            $suffix = if ($isIdLike) { 'ById' } else { 'By' + (ConvertTo-OpenApiPascalCase -Word $parameterWords) }
            $candidates.Add("$($draft.Verb)-$($draft.Noun)$suffix")
        }
        $candidates.Add("$($draft.Verb)-$($draft.Noun)$($draft.Record.Method.Substring(0, 1).ToUpperInvariant() + $draft.Record.Method.Substring(1).ToLowerInvariant())")
        $chosen = $candidates | Where-Object { $used.Add($_) } | Select-Object -First 1
        $disambiguated = $chosen -and $chosen -ne $candidates[0]
        $index = 2
        while (-not $chosen)
        {
            $attempt = "$($draft.Verb)-$($draft.Noun)$index"
            if ($used.Add($attempt))
            {
                $chosen = $attempt
                $disambiguated = $true
            }
            $index++
        }

        $draft.Record | Add-Member -NotePropertyName Name -NotePropertyValue $chosen -Force
        $draft.Record | Add-Member -NotePropertyName Disambiguated -NotePropertyValue ([bool]$disambiguated) -Force
        $draft.Record | Add-Member -NotePropertyName Verb -NotePropertyValue $draft.Verb -Force
        $draft.Record | Add-Member -NotePropertyName Noun -NotePropertyValue ($chosen -split '-', 2)[1] -Force
    }

    $Operation
}

function ConvertTo-OpenApiParameterName
{
    <#
    .SYNOPSIS
    Turns a wire name into a safe PascalCase PowerShell parameter name.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$WireName
    )

    $name = ConvertTo-OpenApiPascalCase -Word @(Split-OpenApiWord -Text $WireName)
    if (-not $name)
    {
        $name = 'Value'
    }
    if ($name -match '^\d')
    {
        $name = 'P' + $name
    }
    if ($name -eq 'Input')
    {
        return 'InputText'
    }
    if ($name -in $Script:OpenApiReservedParameter)
    {
        return $name + 'Value'
    }
    $name
}
