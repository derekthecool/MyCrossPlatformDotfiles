# Lessons from importing real services: an ASP.NET Core/Swashbuckle spec (no summaries, no operationIds,
# catch-all proxy route) and a Go/swaggo Swagger 2.0 spec ("Authorization" apiKey, host without schemes).

BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
    $fixtures = Join-Path $PSScriptRoot 'Fixtures'

    function Invoke-Generator
    {
        New-OpenApiClient @args -PassThru 6>$null 3>$null
    }

    function New-FakeResponse
    {
        param([int]$Status = 200, [string]$ContentType = 'application/json', [string]$Text = '{"ok":true}')
        [pscustomobject]@{
            StatusCode       = $Status
            Headers          = @{ 'Content-Type' = $ContentType }
            Content          = $Text
            RawContentStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($Text))
        }
    }

    function New-TestCredential
    {
        param([string]$User = 'user', [string]$Secret = 'pass')
        $secure = [System.Security.SecureString]::new()
        foreach ($character in $Secret.ToCharArray())
        {
            $secure.AppendChar($character)
        }
        [pscredential]::new($User, $secure)
    }

    # Both specs go into ONE module directory sharing a single runtime, then get bundled into a single psm1 exactly
    # like a psake-style build step does (every source/*.ps1, sorted by name, concatenated).
    $script:source = Join-Path $TestDrive 'Shared/source'
    $script:fleet = Invoke-Generator -Path (Join-Path $fixtures 'aspnet.v3.json') -Name FleetManager -Prefix Fleet -RuntimeName Shared -OutputPath $script:source -DefaultEndpoint 'http://fleet.example.test:5010'
    $script:runtimeStamp = (Get-Item -LiteralPath $script:fleet.RuntimePath).LastWriteTimeUtc
    Start-Sleep -Milliseconds 50
    $script:vpn = Invoke-Generator -Path (Join-Path $fixtures 'swaggo.swagger2.json') -Name PeerRegistry -Prefix Vpn -RuntimeName Shared -OutputPath $script:source -DefaultEndpoint 'http://registry.example.test:1900'

    $bundle = Join-Path $TestDrive 'Shared/SharedApi.psm1'
    Get-ChildItem $script:source -File -Recurse -Filter '*.ps1' | Sort-Object Name | Get-Content | Set-Content $bundle -Encoding UTF8
    Import-Module $bundle -Force

    Mock Invoke-WebRequest -ModuleName SharedApi -MockWith {
        $global:OpenApiTestCalls.Add([pscustomobject]@{ Uri = $Uri.OriginalString; Method = "$Method"; Body = $Body; Headers = $Headers })
        $global:OpenApiTestResponse
    }
}

AfterAll {
    Remove-Module SharedApi -Force -ErrorAction SilentlyContinue
    Remove-Variable -Name OpenApiTestCalls, OpenApiTestResponse -Scope Global -ErrorAction SilentlyContinue
}

Describe 'ASP.NET Core spec without summaries or operationIds' {
    BeforeEach {
        $global:OpenApiTestCalls = [System.Collections.Generic.List[object]]::new()
        $global:OpenApiTestResponse = New-FakeResponse
    }

    It 'names operations from the route and HTTP method' {
        $expected = 'Search-FleetDevice', 'New-FleetDeviceType', 'Get-FleetDuplicateDevice', 'Get-FleetDuplicateDeviceById',
        'Get-FleetProgram', 'Get-FleetProgramByHostname', 'Remove-FleetProgram', 'Get-FleetProgramDeviceCount',
        'Get-FleetProgramProxy', 'New-FleetProgramProxy', 'Set-FleetProgramProxy', 'Remove-FleetProgramProxy', 'Update-FleetProgramProxy'
        foreach ($name in $expected)
        {
            $name | Should -BeIn $script:fleet.Function
        }
        $script:fleet.Function | Where-Object { $_ -match 'Api|Post|Get-Fleet.*Get$' } | Should -BeNullOrEmpty -Because 'no route noise such as "api" or the method may leak into names'
    }

    It 'treats a trailing action segment as the verb' {
        (Get-Command Search-FleetDevice).Parameters.Keys | Should -Contain 'DeviceIds'
        $null = Search-FleetDevice -DeviceIds A, B
        $global:OpenApiTestCalls[0].Uri | Should -Be 'http://fleet.example.test:5010/api/devices/search'
        $global:OpenApiTestCalls[0].Method | Should -Be 'POST'
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"deviceIds":["A","B"]}'
    }

    It 'types responses that are declared for several content types' {
        (Get-Command Search-FleetDevice).OutputType.Name | Should -Be 'Fleet.DeviceSearchResult'
    }

    It 'sends a bare array body for a root array schema' {
        $null = New-FleetDeviceType -Body 'X', 'Y'
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '["X","Y"]'
    }

    It 'keeps slashes in a trailing catch-all parameter but escapes other segments' {
        $proxy = @{ DeviceType = 'b 57'; ComputerName = 'pc01' }
        $null = Get-FleetProgramProxy @proxy -Path 'api/status/a b'
        $global:OpenApiTestCalls[0].Uri | Should -Be 'http://fleet.example.test:5010/api/programs/b%2057/pc01/proxy/api/status/a%20b'
        $null = Get-FleetProgram
        $null = Get-FleetProgramByHostname -Broker mqtt -DeviceType 'x/y' -Hostname 'h'
        $global:OpenApiTestCalls[-1].Uri | Should -Be 'http://fleet.example.test:5010/api/programs/mqtt/x%2Fy/h'
    }

    It 'supports all five proxy methods through the same route' {
        $proxy = @{ DeviceType = 't'; ComputerName = 'c' }
        $null = Get-FleetProgramProxy @proxy -Path p
        $null = New-FleetProgramProxy @proxy -Path p
        $null = Set-FleetProgramProxy @proxy -Path p -Confirm:$false
        $null = Update-FleetProgramProxy @proxy -Path p -Confirm:$false
        $null = Remove-FleetProgramProxy @proxy -Path p -Confirm:$false
        $global:OpenApiTestCalls.Method | Should -Be @('GET', 'POST', 'PUT', 'PATCH', 'DELETE')
        @($global:OpenApiTestCalls.Uri | Select-Object -Unique).Count | Should -Be 1
    }

    It 'honours -RawPathParameter for other catch-all names' {
        $result = Invoke-Generator -Path (Join-Path $fixtures 'aspnet.v3.json') -Name Raw -OutputPath (Join-Path $TestDrive 'raw') -RawPathParameter hostname
        (Get-Content -LiteralPath $result.ClientPath -Raw) | Should -Match "RawPathName\s+= @\('hostname'\)"
        (Get-Content -LiteralPath $script:fleet.ClientPath -Raw) | Should -Match "RawPathName\s+= @\('path'\)"
        (Get-Content -LiteralPath $script:fleet.ClientPath -Raw) | Should -Not -Match "RawPathName\s+= @\('hostname'\)"
    }
}

Describe 'Go/swaggo Swagger 2.0 spec' {
    BeforeEach {
        $global:OpenApiTestCalls = [System.Collections.Generic.List[object]]::new()
        $global:OpenApiTestResponse = New-FakeResponse
    }

    It 'drops prepositional phrases and recognises action words' {
        $expected = 'Get-VpnDevice', 'Add-VpnDevice', 'Remove-VpnDevice', 'Get-VpnDeviceStatus', 'Restore-VpnDevice', 'Invoke-VpnKeyRotation', 'Test-VpnHealth', 'Test-VpnDatabaseHealth'
        foreach ($name in $expected)
        {
            $name | Should -BeIn $script:vpn.Function
        }
    }

    It 'uses the baked-in endpoint and a slash base path correctly' {
        $null = Test-VpnHealth
        $global:OpenApiTestCalls[0].Uri | Should -Be 'http://registry.example.test:1900/health'
    }

    It 'prefixes a bare token with Bearer for an Authorization apiKey scheme' {
        $null = Get-VpnDevice -Credential (New-TestCredential ignored tok123)
        $global:OpenApiTestCalls[0].Headers['Authorization'] | Should -Be 'Bearer tok123'
    }

    It 'leaves a token that already carries a scheme untouched' {
        $null = Get-VpnDevice -Credential (New-TestCredential ignored 'Bearer abc')
        $global:OpenApiTestCalls[0].Headers['Authorization'] | Should -Be 'Bearer abc'
    }

    It 'sends body parameters and path parameters with underscores' {
        $null = Add-VpnDevice -DeviceIds AABBCC, 112233
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"device_ids":["AABBCC","112233"]}'
    }

    It 'tags typed responses with the dotted schema name' {
        (Get-Command Get-VpnDeviceStatus).OutputType.Name | Should -Be 'Vpn.db.Device'
    }

    It 'has constructors only for nested object types' {
        Get-Command -Module SharedApi -Name 'New-Vpn*' | Should -BeNullOrEmpty
    }
}

Describe 'Swagger 2.0 host without schemes' {
    It '<HostName> -> <Expected>' -ForEach @(
        @{ HostName = 'localhost:8080'; Expected = 'http://localhost:8080' }
        @{ HostName = '127.0.0.1'; Expected = 'http://127.0.0.1' }
        @{ HostName = '10.1.2.3:9000'; Expected = 'http://10.1.2.3:9000' }
        @{ HostName = 'api.example.com'; Expected = 'https://api.example.com' }
        @{ HostName = 'api.example.com:443'; Expected = 'https://api.example.com:443' }
        @{ HostName = 'api.example.com:8443'; Expected = 'http://api.example.com:8443' }
    ) {
        $path = Join-Path $TestDrive "scheme-$([guid]::NewGuid().ToString('N')).json"
        @{ swagger = '2.0'; info = @{ title = 'T'; version = '1' }; host = $HostName; paths = @{} } | ConvertTo-Json | Set-Content -LiteralPath $path
        $doc = (InModuleScope DotWebApi -Parameters @{ P = $path } { Import-OpenApiDocument -Path $P }).Document
        $doc.servers[0].url | Should -Be $Expected
    }

    It 'honours an explicit schemes list' {
        $path = Join-Path $TestDrive 'schemes.json'
        @{ swagger = '2.0'; info = @{ title = 'T'; version = '1' }; host = 'localhost:8080'; schemes = @('https'); paths = @{} } | ConvertTo-Json | Set-Content -LiteralPath $path
        ((InModuleScope DotWebApi -Parameters @{ P = $path } { Import-OpenApiDocument -Path $P }).Document).servers[0].url | Should -Be 'https://localhost:8080'
    }
}

Describe 'Several clients sharing one runtime in one module' {
    It 'writes a single runtime file used by both clients' {
        $script:fleet.RuntimePath | Should -Be $script:vpn.RuntimePath
        $script:fleet.RuntimePath | Should -BeLike '*private*Shared.Runtime.ps1'
        @(Get-ChildItem (Join-Path $script:source 'private') -File).Count | Should -Be 1
        (Get-Item -LiteralPath $script:fleet.RuntimePath).LastWriteTimeUtc | Should -Be $script:runtimeStamp -Because 'the second client regenerates an identical runtime, which must not rewrite the file'
    }

    It 'leaves no mention of the generator in the generated files, so the target repository stands alone' {
        $files = Get-ChildItem $script:source -File -Recurse -Filter '*.ps1'
        $files.Count | Should -Be 3
        foreach ($file in $files)
        {
            (Get-Content -LiteralPath $file.FullName -Raw) | Should -Not -Match 'DotWebApi|New-OpenApiClient|OpenApiGeneration|Update-ModuleManifestExport' -Because $file.Name
        }
    }

    It 'does not need any generator command to load or run' {
        $called = foreach ($file in Get-ChildItem $script:source -File -Recurse -Filter '*.ps1')
        {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() }
        }
        $defined = foreach ($file in Get-ChildItem $script:source -File -Recurse -Filter '*.ps1')
        {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true).Name
        }
        $generatorCommands = (Get-Module DotWebApi).ExportedFunctions.Keys + 'ConvertTo-OpenApiBodyTable', 'Invoke-OpenApiRequest', 'Resolve-OpenApiEndpoint'
        @($called | Where-Object { $_ -and $_ -notin $defined -and $_ -in $generatorCommands }) | Should -BeNullOrEmpty
    }

    It 'defines the runtime exactly once and calls it from both clients' {
        $definitions = foreach ($file in Get-ChildItem $script:source -File -Recurse -Filter '*.ps1')
        {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false).Name
        }
        @($definitions | Where-Object { $_ -eq 'Invoke-SharedApiRequest' }).Count | Should -Be 1
        foreach ($client in $script:fleet.ClientPath, $script:vpn.ClientPath)
        {
            (Get-Content -LiteralPath $client -Raw) | Should -Match 'Invoke-SharedApiRequest @request'
        }
    }

    It 'keeps runtime helpers out of the exported function list' {
        $script:fleet.Function | Should -Not -Contain 'Invoke-SharedApiRequest'
        $script:vpn.Function | Should -Not -Contain 'Invoke-SharedApiRequest'
    }

    It 'uses per-API endpoint helpers so clients do not clobber each other' {
        Get-FleetDefaultEndpoint | Should -Be 'http://fleet.example.test:5010'
        Get-VpnDefaultEndpoint | Should -Be 'http://registry.example.test:1900'
    }

    It 'registers each client separately in a psakefile-style export scan, skipping private' {
        $found = InModuleScope DotWebApi -Parameters @{ Source = $script:source } { Get-ModuleSourceExport -Path $Source }
        $found.Function | Should -Contain 'Search-FleetDevice'
        $found.Function | Should -Contain 'Test-VpnHealth'
        $found.Function | Should -Not -Contain 'Invoke-SharedApiRequest'
    }

    It 'updates a BOM-encoded manifest that already lists other functions' {
        $manifest = Join-Path $TestDrive 'Shared.Api.psd1'
        [System.IO.File]::WriteAllText($manifest, "@{`r`n    RootModule        = 'Shared.Api.psm1'`r`n    ModuleVersion     = '0.1.0'`r`n    GUID              = 'accb0bd2-2ed6-47f4-888e-8925dad8b74c'`r`n    AliasesToExport   = @(`r`n        'gs'`r`n    )`r`n    FunctionsToExport = @(`r`n        'Get-Something'`r`n    )`r`n}`r`n", [System.Text.UTF8Encoding]::new($true))
        Set-Content -LiteralPath (Join-Path $TestDrive 'Shared.Api.psm1') -Value ''
        $null = Invoke-Generator -Path (Join-Path $fixtures 'aspnet.v3.json') -Name FleetManager -Prefix Fleet -RuntimeName Shared -OutputPath (Join-Path $TestDrive 'bom/source') -ManifestPath $manifest -UpdateManifest
        $null = Invoke-Generator -Path (Join-Path $fixtures 'swaggo.swagger2.json') -Name PeerRegistry -Prefix Vpn -RuntimeName Shared -OutputPath (Join-Path $TestDrive 'bom/source') -ManifestPath $manifest -UpdateManifest
        $bytes = [System.IO.File]::ReadAllBytes($manifest)
        $bytes[0..2] | Should -Be @(0xEF, 0xBB, 0xBF)
        $data = Import-PowerShellDataFile -LiteralPath $manifest
        $data.AliasesToExport | Should -Be @('gs')
        $data.FunctionsToExport | Should -Contain 'Get-Something'
        $data.FunctionsToExport | Should -Contain 'Search-FleetDevice'
        $data.FunctionsToExport | Should -Contain 'Test-VpnHealth'
        $text = [System.IO.File]::ReadAllText($manifest)
        $text | Should -Match '# BEGIN generated: FleetManager'
        $text | Should -Match '# BEGIN generated: PeerRegistry'
    }
}

Describe 'AutoRest-era spec with method-style operationIds and an ApiKey header' {
    BeforeAll {
        $script:legacyNames = 'Get-Searchdevice', 'Invoke-BulkAssignAsyncPut', 'Get-Geofence', 'Connect-Gadget'
        $script:pine = Invoke-Generator -Path (Join-Path $fixtures 'methodstyle.v3.json') -Name PhsDevice -Prefix Gadget -RuntimeName Shared -OutputPath (Join-Path $TestDrive 'pine') -ReservedName $script:legacyNames
        $pineSource = Join-Path $TestDrive 'pine'
        $bundle = Join-Path $TestDrive 'pine/PineClient.psm1'
        Get-ChildItem $pineSource -File -Recurse -Filter '*.ps1' | Sort-Object Name | Get-Content | Set-Content $bundle -Encoding UTF8
        Import-Module $bundle -Force
        Mock Invoke-WebRequest -ModuleName PineClient -MockWith {
            $global:OpenApiTestCalls.Add([pscustomobject]@{ Uri = $Uri.OriginalString; Method = "$Method"; Body = $Body; Headers = $Headers })
            $global:OpenApiTestResponse
        }
    }

    BeforeEach {
        $global:OpenApiTestCalls = [System.Collections.Generic.List[object]]::new()
        $global:OpenApiTestResponse = New-FakeResponse
    }

    AfterAll {
        Remove-Module PineClient -Force -ErrorAction SilentlyContinue
    }

    It 'drops the leading HTTP-method word and lets the method choose the verb (POST is Invoke, as in AutoRest)' {
        $expected = 'Get-GadgetSearchdevice', 'Reset-GadgetDevice', 'Invoke-GadgetBulkAssignAsyncPut',
        'Invoke-GadgetBulkSubscriberAsyncGet', 'Invoke-GadgetBulkSubscriberAsyncPut', 'Get-GadgetGeofence',
        'Get-GadgetGeofenceById', 'Remove-GadgetGeofence', 'Invoke-GadgetGeofence'
        foreach ($name in $expected)
        {
            $name | Should -BeIn $script:pine.Function
        }
        $script:pine.Function | Where-Object { $_ -match 'Post|ByDeviceid' } | Should -BeNullOrEmpty
    }

    It 'keeps trailing method echoes so sibling bulk operations stay distinct' {
        @($script:pine.Function | Where-Object { $_ -like 'Invoke-GadgetBulkSubscriber*' }).Count | Should -Be 2
    }

    It 'reports only genuinely disambiguated names' {
        $script:pine.Renamed | Should -Be @('Get-GadgetGeofenceById')
    }

    It 'avoids names that an older module already exports' {
        $names = (Invoke-Generator -Path (Join-Path $fixtures 'methodstyle.v3.json') -Prefix Gadget -OutputPath (Join-Path $TestDrive 'reserve') -ReservedName 'Get-GadgetGeofence', 'New-GadgetFence').Function
        $names | Should -Not -Contain 'Get-GadgetGeofence'
        $names | Should -Not -Contain 'New-GadgetFence'
        $names | Should -Contain 'Get-GadgetGeofenceById'
    }

    It 'refuses a prefix whose helper commands collide with reserved names' {
        { New-OpenApiClient -Path (Join-Path $fixtures 'methodstyle.v3.json') -Prefix Gadget -OutputPath (Join-Path $TestDrive 'clash') -ReservedName 'Set-GadgetCredential' 6>$null } | Should -Throw '*collide*'
    }

    It 'uses the spec server when no default endpoint is baked in' {
        $null = Get-GadgetSearchdevice -DeviceId abc
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://device.example.com/searchDevice/abc'
    }

    It 'sends the bare token in the ApiKey header and tolerates a pasted "apikey " prefix' {
        $null = Get-GadgetGeofence -Credential (New-TestCredential x secret-token)
        $global:OpenApiTestCalls[0].Headers['ApiKey'] | Should -Be 'secret-token'
        $global:OpenApiTestCalls[0].Headers.Keys | Should -Not -Contain 'Authorization'
        $null = Get-GadgetGeofence -Credential (New-TestCredential x 'apikey secret-token')
        $global:OpenApiTestCalls[1].Headers['ApiKey'] | Should -Be 'secret-token'
    }

    It 'resets a device with the key taken from the path' {
        $null = Reset-GadgetDevice -DeviceId dev1
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://device.example.com/dev1/reset'
        $global:OpenApiTestCalls[0].Method | Should -Be 'POST'
    }

    It 'offers a secret-based credential helper like a hand-written Connect- command' {
        $parameters = (Get-Command Set-GadgetCredential).Parameters
        $parameters.Keys | Should -Contain 'FromSecret'
        $parameters['SecretName'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Count | Should -BeGreaterThan 0
        (Get-Content -LiteralPath $script:pine.ClientPath -Raw) | Should -Match "\[string\]\`$SecretName = 'GadgetApiKey'"
    }
}
