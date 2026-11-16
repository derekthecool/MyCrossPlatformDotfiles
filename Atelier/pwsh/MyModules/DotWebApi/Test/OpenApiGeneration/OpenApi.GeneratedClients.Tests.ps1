BeforeDiscovery {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    $definitions = Import-PowerShellDataFile -LiteralPath (Join-Path $moduleRoot 'examples/GeneratedClients.psd1')
    $script:clients = @($definitions.Keys | Sort-Object | ForEach-Object { @{ Name = $_; NeedsYaml = [bool]($definitions[$_].Path -match '\.ya?ml$') } })
    $script:hasYaml = [bool](Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)
    $script:hasAnalyzer = [bool](Get-Module -ListAvailable -Name PSScriptAnalyzer)
}

BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
    $definitions = Import-PowerShellDataFile -LiteralPath (Join-Path $moduleRoot 'examples/GeneratedClients.psd1')
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $moduleRoot 'DotWebApi.psd1')

    function Get-DefinedFunction
    {
        param([string]$Path)
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
        $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false).Name
    }

    function New-TestSecret
    {
        param([string]$Text)
        $secure = [System.Security.SecureString]::new()
        foreach ($character in $Text.ToCharArray())
        {
            $secure.AppendChar($character)
        }
        $secure
    }

    function New-FakeResponse
    {
        param([int]$Status = 200, [string]$ContentType = 'application/json', [string]$Text = '{}')
        [pscustomobject]@{
            StatusCode       = $Status
            Headers          = @{ 'Content-Type' = $ContentType }
            Content          = $Text
            RawContentStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($Text))
        }
    }
}

Describe 'Committed client <Name>' -ForEach $script:clients {
    BeforeAll {
        $definition = $definitions[$Name]
        $script:result = $null
        if (-not ($NeedsYaml -and -not (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)))
        {
            $arguments = @{
                Path       = Join-Path $moduleRoot $definition.Path
                Name       = $Name
                OutputPath = Join-Path $TestDrive "regenerated-$Name"
            }
            if ($definition.DefaultEndpoint) { $arguments.DefaultEndpoint = $definition.DefaultEndpoint }
            if ($definition.NameOverride) { $arguments.NameOverride = $definition.NameOverride }
            $script:result = New-OpenApiClient @arguments -RuntimeMode Module -PassThru 6>$null 3>$null
        }
        $script:committed = Join-Path $moduleRoot (Join-Path $definition.OutputPath "$Name.ps1")
    }

    It 'matches what the generator produces (run examples/Update-GeneratedClients.ps1 to refresh it)' -Skip:($NeedsYaml -and -not $script:hasYaml) {
        # A Windows checkout with autocrlf may hold CRLF; the generator always writes LF.
        $fresh = (Get-Content -LiteralPath $script:result.ClientPath -Raw) -replace "`r`n", "`n"
        $fresh | Should -BeExactly ((Get-Content -LiteralPath $script:committed -Raw) -replace "`r`n", "`n")
    }

    It 'lists every command it defines in DotWebApi.psd1' -Skip:($NeedsYaml -and -not $script:hasYaml) {
        $missing = $script:result.Function | Where-Object { $_ -notin $manifest.FunctionsToExport }
        $missing | Should -BeNullOrEmpty
    }

    It 'uses approved verbs only' -Skip:($NeedsYaml -and -not $script:hasYaml) {
        $approved = (Get-Verb).Verb
        $script:result.Function | Where-Object { ($_ -split '-')[0] -notin $approved } | Should -BeNullOrEmpty
    }

    It 'is clean under the repository PSScriptAnalyzer settings' -Skip:(-not $script:hasAnalyzer) {
        $settings = Join-Path $moduleRoot '../../PSScriptAnalyzerSettings.psd1'
        $params = if (Test-Path $settings) { @{ Settings = $settings } } else { @{ Severity = 'Error' } }
        Invoke-ScriptAnalyzer -Path $script:committed @params | Should -BeNullOrEmpty
    }
}

Describe 'All committed clients together' {
    It 'define each command once' {
        $names = foreach ($name in $definitions.Keys)
        {
            Get-DefinedFunction -Path (Join-Path $moduleRoot (Join-Path $definitions[$name].OutputPath "$name.ps1"))
        }
        $duplicates = $names | Group-Object | Where-Object Count -GT 1 | ForEach-Object Name
        $duplicates | Should -BeNullOrEmpty
    }

    It 'only the generated names appear inside their BEGIN/END blocks in DotWebApi.psd1' {
        $text = Get-Content -LiteralPath (Join-Path $moduleRoot 'DotWebApi.psd1') -Raw
        foreach ($name in $definitions.Keys)
        {
            $text | Should -Match "# BEGIN generated: $name\r?\n"
            $text | Should -Match "# END generated: $name\r?\n"
        }
    }
}

Describe 'The new clients against a mocked server' {
    BeforeAll {
        $global:GeneratedClientCalls = [System.Collections.Generic.List[object]]::new()
        $global:GeneratedClientResponse = New-FakeResponse
        Mock Invoke-WebRequest -ModuleName DotWebApi -MockWith {
            $global:GeneratedClientCalls.Add([pscustomobject]@{ Uri = $Uri.OriginalString; Method = "$Method"; Body = $Body; Form = $Form; ContentType = $ContentType })
            $global:GeneratedClientResponse
        }
        # Never read a saved endpoint from the machine running the tests.
        Mock Get-OpenApiClientSettingPath -ModuleName DotWebApi -MockWith { Join-Path $TestDrive 'no-saved-settings.xml' }
    }

    BeforeEach {
        $global:GeneratedClientCalls.Clear()
        foreach ($variable in 'FRIGATE_ENDPOINT', 'OPENFOODFACTS_ENDPOINT', 'OPENMETEOFORECAST_ENDPOINT') { Remove-Item "Env:$variable" -ErrorAction SilentlyContinue }
    }

    AfterAll {
        Remove-Variable -Name GeneratedClientCalls, GeneratedClientResponse -Scope Global -ErrorAction SilentlyContinue
    }

    Context 'Frigate' {
        It 'defaults to the configured server and the spec''s /api base path' {
            $null = Get-FrigateVersion
            $global:GeneratedClientCalls[0].Method | Should -Be 'GET'
            $global:GeneratedClientCalls[0].Uri | Should -Be 'http://192.168.1.91:5000/api/version'
        }

        It 'takes another server with -Endpoint, keeping the base path' {
            $null = Get-FrigateVersion -Endpoint 'http://frigate.example.test:5000'
            $global:GeneratedClientCalls[0].Uri | Should -Be 'http://frigate.example.test:5000/api/version'
        }

        It 'sends a SecureString password as text in the request body' {
            $secure = New-TestSecret 'p@ss word'
            $null = Invoke-FrigateLoginWithCredential -User admin -Password $secure
            $global:GeneratedClientCalls[0].Method | Should -Be 'POST'
            $global:GeneratedClientCalls[0].Uri | Should -Be 'http://192.168.1.91:5000/api/login'
            $global:GeneratedClientCalls[0].Body | Should -BeExactly '{"user":"admin","password":"p@ss word"}'
        }

        It 'also converts a SecureString passed inside -InputObject' {
            $secure = New-TestSecret 'hunter2'
            $null = Invoke-FrigateLoginWithCredential -InputObject ([ordered]@{ user = 'admin'; password = $secure })
            $global:GeneratedClientCalls[0].Body | Should -BeExactly '{"user":"admin","password":"hunter2"}'
        }

        It 'uses the verbs and nouns chosen in GeneratedClients.psd1' -ForEach @(
            @{ Name = 'Test-FrigateHealth' }, @{ Name = 'Get-FrigateEvent' }, @{ Name = 'Get-FrigateEventById' },
            @{ Name = 'Set-FrigateCameraFeature' }, @{ Name = 'Restore-FrigateNotice' }, @{ Name = 'Get-FrigateCameraRecordingsSummary' }
        ) {
            Get-Command -Name $Name -Module DotWebApi | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Open Food Facts' {
        It 'looks a product up on the production server' {
            $null = Get-OpenFoodFactsProduct -Code 3017620422003 -Fields 'product_name,brands'
            $global:GeneratedClientCalls[0].Method | Should -Be 'GET'
            $global:GeneratedClientCalls[0].Uri | Should -Match '^https://world\.openfoodfacts\.org/api/v2/product/3017620422003\?fields=product_name(,|%2C)brands$'
        }

        It 'uses the staging server when asked' {
            $null = Get-OpenFoodFactsProduct -Code 1 -Endpoint 'https://world.openfoodfacts.net'
            $global:GeneratedClientCalls[0].Uri | Should -BeLike 'https://world.openfoodfacts.net/api/v2/product/1*'
        }

        It 'sends the credential fields of a product edit, the password as text' {
            $secure = New-TestSecret 'secret'
            $null = Update-OpenFoodFactsProduct -Code 1 -UserId me -Password $secure -ProductName 'Thing'
            $call = $global:GeneratedClientCalls[0]
            $call.Method | Should -Be 'POST'
            $call.Uri | Should -Be 'https://world.openfoodfacts.org/cgi/product_jqm2.pl'
            # Sent as a form, however the runtime encodes it: look at both places the fields can be.
            $sent = "$($call.Body) $(($call.Form | ConvertTo-Json -Compress -Depth 3))"
            $sent | Should -Match 'password.{1,5}secret'
            $sent | Should -Match 'user_id.{1,5}me'
            $sent | Should -Not -Match 'System\.Security'
        }

        It 'resolves the shared parameters and schemas of the split spec' {
            $parameters = (Get-Command Get-OpenFoodFactsProduct).Parameters.Keys
            $parameters | Should -Contain 'Code'
            $parameters | Should -Contain 'Fields'
        }
    }

    Context 'Open-Meteo' {
        It 'asks the forecast host for a forecast, with array values comma-separated' {
            $null = Get-OpenMeteoForecast -Latitude '40.76' -Longitude '-111.89' -Hourly temperature_2m, rain
            $uri = $global:GeneratedClientCalls[0].Uri
            $uri | Should -BeLike 'https://api.open-meteo.com/v1/forecast?*'
            $uri | Should -Match 'latitude=40\.76'
            $uri | Should -Match 'longitude=-111\.89'
            $uri | Should -Match 'hourly=temperature_2m(,|%2C)rain'
        }

        It 'has one host per API, each with its own endpoint commands' -ForEach @(
            @{ Command = 'Get-OpenMeteoAirQualityDefaultEndpoint'; Expected = 'https://air-quality-api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoClimateDefaultEndpoint'; Expected = 'https://climate-api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoElevationDefaultEndpoint'; Expected = 'https://api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoEnsembleDefaultEndpoint'; Expected = 'https://ensemble-api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoFloodDefaultEndpoint'; Expected = 'https://flood-api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoForecastDefaultEndpoint'; Expected = 'https://api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoHistoricalWeatherDefaultEndpoint'; Expected = 'https://archive-api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoMarineDefaultEndpoint'; Expected = 'https://marine-api.open-meteo.com' }
            @{ Command = 'Get-OpenMeteoSeasonalDefaultEndpoint'; Expected = 'https://seasonal-api.open-meteo.com' }
        ) {
            & $Command | Should -Be $Expected
        }

        It 'sends the historical weather request to /v1/archive' {
            $null = Get-OpenMeteoHistoricalWeather -Latitude '1' -Longitude '2' -StartDate 2025-01-01 -EndDate 2025-01-02
            $global:GeneratedClientCalls[0].Uri | Should -BeLike 'https://archive-api.open-meteo.com/v1/archive?*'
        }
    }
}

Describe 'Password parameters of a generated client' {
    BeforeAll {
        $spec = Join-Path $TestDrive 'accounts.v3.json'
        Set-Content -LiteralPath $spec -Value @'
{
  "openapi": "3.0.3",
  "info": { "title": "Accounts", "version": "1" },
  "servers": [{ "url": "https://accounts.example.test" }],
  "paths": {
    "/login": {
      "post": {
        "summary": "Log in",
        "requestBody": { "required": true, "content": { "application/json": { "schema": { "type": "object", "required": ["username", "password"], "properties": {
          "username": { "type": "string" },
          "password": { "type": "string", "description": "Account password" },
          "old_password": { "type": "string" },
          "note": { "type": "string" } } } } } },
        "responses": { "200": { "description": "OK" } }
      }
    },
    "/check": {
      "get": {
        "summary": "Check pin",
        "parameters": [{ "name": "pin", "in": "query", "schema": { "type": "string", "format": "password" } }],
        "responses": { "200": { "description": "OK" } }
      }
    }
  }
}
'@
        $directory = Join-Path $TestDrive 'accountsclient'
        $script:accounts = New-OpenApiClient -Path $spec -Name Accounts -OutputPath $directory -RuntimeMode Embedded -PassThru 6>$null
        Set-Content -LiteralPath (Join-Path $directory 'Accounts.psm1') -Value 'Get-ChildItem $PSScriptRoot -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }'
        Import-Module (Join-Path $directory 'Accounts.psm1') -Force
        $global:AccountsCalls = [System.Collections.Generic.List[object]]::new()
        Mock Invoke-WebRequest -ModuleName Accounts -MockWith {
            $global:AccountsCalls.Add([pscustomobject]@{ Uri = $Uri.OriginalString; Body = $Body })
            [pscustomobject]@{ StatusCode = 200; Headers = @{ 'Content-Type' = 'application/json' }; Content = '{}'; RawContentStream = [System.IO.MemoryStream]::new([byte[]](123, 125)) }
        }
        Mock Get-AccountsApiClientSettingPath -ModuleName Accounts -MockWith { Join-Path $TestDrive 'none.xml' }
    }

    AfterAll {
        Remove-Module Accounts -Force -ErrorAction SilentlyContinue
        Remove-Variable -Name AccountsCalls -Scope Global -ErrorAction SilentlyContinue
    }

    It 'types password-like fields as SecureString and leaves other strings alone' {
        $parameters = (Get-Command Get-AccountsLogIn -ErrorAction SilentlyContinue)?.Parameters
        if (-not $parameters)
        {
            $parameters = (Get-Command -Module Accounts | Where-Object Name -Match 'Accounts' | Where-Object { $_.Parameters.ContainsKey('Password') } | Select-Object -First 1).Parameters
        }
        $parameters['Password'].ParameterType | Should -Be ([securestring])
        $parameters['OldPassword'].ParameterType | Should -Be ([securestring])
        $parameters['Username'].ParameterType | Should -Be ([string])
        $parameters['Note'].ParameterType | Should -Be ([string])
    }

    It 'honours format: password on a query parameter' {
        $command = Get-Command -Module Accounts | Where-Object { $_.Parameters.ContainsKey('Pin') } | Select-Object -First 1
        $command.Parameters['Pin'].ParameterType | Should -Be ([securestring])
    }

    It 'sends the password as text' {
        $login = Get-Command -Module Accounts | Where-Object { $_.Parameters.ContainsKey('Password') } | Select-Object -First 1
        $secure = New-TestSecret 's3cret'
        $null = & $login -Username me -Password $secure -OldPassword $secure
        $global:AccountsCalls[-1].Body | Should -BeExactly '{"username":"me","password":"s3cret","old_password":"s3cret"}'
    }

    It 'sends a password-format query value as text' {
        $check = Get-Command -Module Accounts | Where-Object { $_.Parameters.ContainsKey('Pin') } | Select-Object -First 1
        $null = & $check -Pin (New-TestSecret '1234')
        $global:AccountsCalls[-1].Uri | Should -Be 'https://accounts.example.test/check?pin=1234'
    }

    It 'shows a SecureString in the generated help example' {
        $text = Get-Content -LiteralPath $script:accounts.ClientPath -Raw
        $text | Should -Match '-Password \(Read-Host -AsSecureString\)'
    }
}
