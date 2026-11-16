BeforeDiscovery {
    $script:hasYaml = [bool](Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)
}

BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
    $fixtures = Join-Path $PSScriptRoot 'Fixtures'

    function Get-AllReference
    {
        # Every '$ref' string anywhere in a parsed document, except under examples (never followed).
        param($Node)
        if ($Node -is [System.Collections.IDictionary])
        {
            foreach ($key in $Node.Keys)
            {
                if ($key -eq '$ref' -and $Node[$key] -is [string])
                {
                    $Node[$key]
                } elseif ($key -in 'example', 'examples')
                {
                    continue
                } else
                {
                    Get-AllReference -Node $Node[$key]
                }
            }
        } elseif ($Node -is [System.Collections.IList])
        {
            foreach ($item in $Node)
            {
                Get-AllReference -Node $item
            }
        }
    }

    function Import-Split
    {
        param([string]$Root)
        InModuleScope DotWebApi -Parameters @{ Path = $Root } { Import-OpenApiDocument -Path $Path }
    }

    function Copy-SplitFixture
    {
        $copy = Join-Path $TestDrive "split-$([guid]::NewGuid().ToString('N').Substring(0, 6))"
        Copy-Item -LiteralPath (Join-Path $fixtures 'split') -Destination $copy -Recurse
        $copy
    }
}

Describe 'A spec split over several files' {
    BeforeAll {
        $script:rootFile = Join-Path $fixtures 'split/root.json'
        $script:loaded = Import-Split -Root $script:rootFile
        $script:doc = $script:loaded.Document
    }

    It 'leaves only local references behind' {
        $references = @(Get-AllReference -Node $script:doc)
        $references.Count | Should -BeGreaterThan 5
        $references | Where-Object { -not $_.StartsWith('#/') } | Should -BeNullOrEmpty
    }

    It 'resolves every remaining reference' {
        $unresolved = InModuleScope DotWebApi -Parameters @{ Doc = $script:doc; Refs = @(Get-AllReference -Node $script:doc) } {
            foreach ($ref in $Refs)
            {
                try { $null = Resolve-OpenApiReference -Document $Doc -Reference $ref } catch { $ref }
            }
        }
        $unresolved | Should -BeNullOrEmpty
    }

    It 'files whole-file references by position and keeps components names from pointers' {
        $components = $script:doc.components
        $components.parameters.Keys | Should -Contain 'Limit'
        $components.parameters.Keys | Should -Contain 'Page'
        $components.responses.Keys | Should -Contain 'GadgetList'
        $components.requestBodies.Keys | Should -Contain 'NewGadget'
        $components.schemas.Keys | Should -Contain 'Gadget'
        $script:doc.paths['/gadgets'].get.parameters[0]['$ref'] | Should -Be '#/components/parameters/Limit'
        $script:doc.paths['/gadgets'].get.parameters[1]['$ref'] | Should -Be '#/components/parameters/Page'
        $script:doc.paths['/gadgets'].get.responses['200']['$ref'] | Should -Be '#/components/responses/GadgetList'
    }

    It 'resolves references inside an external file against that file' {
        $script:doc.components.responses.GadgetList.content['application/json'].schema.items['$ref'] | Should -Be '#/components/schemas/Gadget'
    }

    It 'points a file''s reference to itself at the same component, so recursion terminates' {
        $script:doc.components.schemas.Gadget.properties.children.items['$ref'] | Should -Be '#/components/schemas/Gadget'
    }

    It 'renames a clashing component instead of overwriting the one already there' {
        $script:doc.components.schemas.Item.properties.Keys | Should -Be @('root')
        $script:doc.components.schemas.Item2.properties.Keys | Should -Be @('common')
        $script:doc.components.schemas.Gadget.properties.tag['$ref'] | Should -Be '#/components/schemas/Item2'
    }

    It 'does not follow examples' {
        $script:loaded.ExternalFiles | Should -Not -Contain 'parts/examples/never-read.json'
        $script:loaded.ExternalFiles | Should -Be @('parts/common.json', 'parts/parameters/limit.json', 'parts/requestBodies/new_gadget.json', 'parts/responses/gadget_list.json', 'parts/schemas/gadget.json')
    }

    It 'hashes every file read, so a change in any part shows up' {
        $rootOnly = (Get-FileHash -LiteralPath $script:rootFile -Algorithm SHA256).Hash.ToLowerInvariant()
        $script:loaded.Sha256 | Should -Not -Be $rootOnly

        $copy = Copy-SplitFixture
        $first = (Import-Split -Root (Join-Path $copy 'root.json')).Sha256
        $first | Should -Be $script:loaded.Sha256 -Because 'the hash depends on content and relative names, not on where the files are'

        Add-Content -LiteralPath (Join-Path $copy 'parts/common.json') -Value ' '
        (Import-Split -Root (Join-Path $copy 'root.json')).Sha256 | Should -Not -Be $first
    }

    It 'names the missing file when a part is gone' {
        $copy = Copy-SplitFixture
        Remove-Item -LiteralPath (Join-Path $copy 'parts/parameters/limit.json')
        { Import-Split -Root (Join-Path $copy 'root.json') } | Should -Throw "*not found*limit.json*referenced as './parts/parameters/limit.json'*"
    }

    It 'keeps the hash of a single-file spec equal to the file hash' {
        $path = Join-Path $moduleRoot 'Source/Kokoro/kokoro_tts_openapi.json'
        $result = Import-Split -Root $path
        $result.Sha256 | Should -Be (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        $result.ExternalFiles | Should -BeNullOrEmpty
    }

    Context 'generated client' {
        BeforeAll {
            $directory = Join-Path $TestDrive 'splitclient'
            $script:result = New-OpenApiClient -Path $script:rootFile -Name Split -OutputPath $directory -RuntimeMode Embedded -PassThru 6>$null
            Set-Content -LiteralPath (Join-Path $directory 'Split.psm1') -Value 'Get-ChildItem $PSScriptRoot -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }'
            Import-Module (Join-Path $directory 'Split.psm1') -Force
            $global:SplitCalls = [System.Collections.Generic.List[string]]::new()
            Mock Invoke-WebRequest -ModuleName Split -MockWith {
                $global:SplitCalls.Add($Uri.OriginalString)
                [pscustomobject]@{ StatusCode = 200; Headers = @{ 'Content-Type' = 'application/json' }; Content = '[]'; RawContentStream = [System.IO.MemoryStream]::new([byte[]](91, 93)) }
            }
            Mock Get-SplitApiClientSettingPath -ModuleName Split -MockWith { Join-Path $TestDrive 'no-such-settings.xml' }
        }

        AfterAll {
            Remove-Module Split -Force -ErrorAction SilentlyContinue
            Remove-Variable -Name SplitCalls -Scope Global -ErrorAction SilentlyContinue
        }

        It 'gets its commands, parameters and validation from the parts' {
            $script:result.Function | Should -Contain 'Get-SplitGadget'
            $script:result.Function | Should -Contain 'New-SplitGadget'
            $script:result.Function | Should -Contain 'Get-SplitGadgetById'
            $parameters = (Get-Command Get-SplitGadget).Parameters
            $parameters.Keys | Should -Contain 'Limit'
            $parameters.Keys | Should -Contain 'Page'
            ($parameters['Limit'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }).MaxRange | Should -Be 100
            (Get-Command New-SplitGadget).Parameters['Name'].Attributes.Mandatory | Should -Contain $true
        }

        It 'calls the spec''s server with the part-defined query parameters' {
            $null = Get-SplitGadget -Limit 5 -Page 2
            $global:SplitCalls[-1] | Should -Be 'https://split.example.test/api/gadgets?limit=5&page=2'
        }
    }
}

Describe 'Servers declared below the top level' {
    It 'falls back to the first path-level or operation-level server, paths in sorted order' {
        $doc = (Import-Split -Root (Join-Path $fixtures 'pathservers.v3.json')).Document
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $doc } { Get-OpenApiServerInfo -Document $Doc }
        $info.ServerUrl | Should -Be 'https://a.example.test'
    }

    It 'splits a path-level server''s base path off' {
        $doc = (Import-Split -Root (Join-Path $fixtures 'pathservers.v3.json')).Document
        $null = $doc.paths.Remove('/a/things')
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $doc } { Get-OpenApiServerInfo -Document $Doc }
        $info.ServerUrl | Should -Be 'https://b.example.test/v2'
        $info.BasePath | Should -Be '/v2'
    }

    It 'prefers a top-level server when there is one' {
        $doc = (Import-Split -Root (Join-Path $fixtures 'split/root.json')).Document
        (InModuleScope DotWebApi -Parameters @{ Doc = $doc } { Get-OpenApiServerInfo -Document $Doc }).ServerUrl | Should -Be 'https://split.example.test/api'
    }
}

Describe 'YAML specs' {
    It 'loads through ConvertFrom-Yaml with string keys and typed values' -Skip:(-not $script:hasYaml) {
        $doc = (Import-Split -Root (Join-Path $fixtures 'gadgets.v3.yaml')).Document
        $doc.info.version | Should -BeExactly '2.0'
        $doc.info.description | Should -Be "Line one.`nLine two.`n"
        $doc.paths['/gadgets'].get.responses.Keys | Should -Contain '200'
        $limit = $doc.paths['/gadgets'].get.parameters | Where-Object name -EQ 'limit'
        $limit.schema.default | Should -Be 10
        $limit.schema.default | Should -BeOfType [int]
    }

    It 'generates a client with the path-level server and the enum as a ValidateSet' -Skip:(-not $script:hasYaml) {
        $directory = Join-Path $TestDrive 'yamlclient'
        $result = New-OpenApiClient -Path (Join-Path $fixtures 'gadgets.v3.yaml') -Name Gadgets -OutputPath $directory -RuntimeMode Embedded -PassThru 6>$null
        $result.Function | Should -Contain 'Get-GadgetsGadget'
        $text = Get-Content -LiteralPath $result.ClientPath -Raw
        $text | Should -Match "ServerUrl\s+=\s+'https://gadgets\.example\.test'"
        $text | Should -Match "ValidateSet\('small', 'large', 'extra large'\)"
    }

    It 'says how to get YAML support when ConvertFrom-Yaml is missing' {
        $path = Join-Path $fixtures 'gadgets.v3.yaml'
        InModuleScope DotWebApi -Parameters @{ Path = $path } {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'ConvertFrom-Yaml' }
            { Import-OpenApiDocument -Path $Path } | Should -Throw '*powershell-yaml*'
        }
    }
}
