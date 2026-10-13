BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
    $fixtures = Join-Path $PSScriptRoot 'Fixtures'

    # Each spec becomes its own throw-away module with an *embedded* runtime, so these tests also prove
    # the generated code works without DotWebApi loaded around it.
    function New-ClientModule
    {
        param([string]$Spec, [string]$Name, [hashtable]$Extra = @{})
        $directory = Join-Path $TestDrive $Name
        $null = New-OpenApiClient -Path $Spec -OutputPath $directory -RuntimeMode Embedded @Extra 6>$null
        $psm1 = Join-Path $directory "$Name.psm1"
        Set-Content -LiteralPath $psm1 -Value 'Get-ChildItem $PSScriptRoot -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }'
        Import-Module $psm1 -Force
    }

    function New-FakeResponse
    {
        param([int]$Status = 200, [string]$ContentType = 'application/json', [string]$Text = '', [byte[]]$Bytes)
        $payload = [System.Text.Encoding]::UTF8.GetBytes($Text)
        if ($Bytes)
        {
            $payload = $Bytes
        }
        [pscustomobject]@{
            StatusCode       = $Status
            Headers          = @{ 'Content-Type' = $ContentType }
            Content          = if ($Bytes) { $Bytes } else { $Text }
            RawContentStream = [System.IO.MemoryStream]::new($payload)
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

    New-ClientModule -Spec (Join-Path $moduleRoot 'Source/Kokoro/kokoro_tts_openapi.json') -Name KokoroClient -Extra @{ DefaultEndpoint = 'http://192.168.1.103:8880' }
    New-ClientModule -Spec (Join-Path $fixtures 'petstore.v3.json') -Name PetClient
    New-ClientModule -Spec (Join-Path $fixtures 'widgets.swagger2.json') -Name WidgetClient

    function Reset-TestState
    {
        $global:OpenApiTestCalls = [System.Collections.Generic.List[object]]::new()
        $global:OpenApiTestResponse = New-FakeResponse -Text '{"ok":true}'
        Remove-Item -LiteralPath $global:OpenApiTestSettingPath -ErrorAction SilentlyContinue
        Set-KokoroCredential -Confirm:$false
        Remove-Item Env:KOKORO_ENDPOINT -ErrorAction SilentlyContinue
    }

    $global:OpenApiTestSettingPath = Join-Path $TestDrive 'kokoro_settings.xml'
    foreach ($module in 'KokoroClient', 'PetClient', 'WidgetClient')
    {
        Mock Invoke-WebRequest -ModuleName $module -MockWith {
            $global:OpenApiTestCalls.Add([pscustomobject]@{
                    Uri = $Uri.OriginalString; Method = "$Method"; Body = $Body; ContentType = $ContentType
                    Headers = $Headers; Form = $Form
                    Timeout = $PesterBoundParameters[($PesterBoundParameters.Keys | Where-Object { $_ -like '*Timeout*' } | Select-Object -First 1)]
                })
            $global:OpenApiTestResponse
        }
    }
    Mock Get-KokoroApiClientSettingPath -ModuleName KokoroClient -MockWith { $global:OpenApiTestSettingPath }
}

AfterAll {
    Remove-Module KokoroClient, PetClient, WidgetClient -Force -ErrorAction SilentlyContinue
    Remove-Variable -Name OpenApiTestCalls, OpenApiTestResponse, OpenApiTestSettingPath -Scope Global -ErrorAction SilentlyContinue
}

Describe 'Kokoro: request construction' {
    BeforeEach { Reset-TestState }

    It 'sends only the bound parameters, as JSON, to the default endpoint' {
        $global:OpenApiTestResponse = New-FakeResponse -ContentType 'audio/wav' -Bytes ([byte[]](82, 73, 70, 70, 1, 2))
        $file = Join-Path $TestDrive 'speech.wav'
        $result = New-KokoroSpeech -InputText 'hi' -Voice af_heart -ResponseFormat wav -OutFile $file

        $global:OpenApiTestCalls.Count | Should -Be 1
        $call = $global:OpenApiTestCalls[0]
        $call.Uri | Should -Be 'http://192.168.1.103:8880/v1/audio/speech'
        $call.Method | Should -Be 'POST'
        $call.ContentType | Should -Be 'application/json'
        $call.Body | Should -BeExactly '{"input":"hi","voice":"af_heart","response_format":"wav"}'
        $result | Should -BeOfType [System.IO.FileInfo]
        $result.FullName | Should -Be $file
        [System.IO.File]::ReadAllBytes($file) | Should -Be ([byte[]](82, 73, 70, 70, 1, 2))
    }

    It 'sends switches and bools by explicit value, including false' {
        $null = New-KokoroSpeech -InputText x -Stream:$false -ReturnDownloadLink -OutFile (Join-Path $TestDrive 'a.bin')
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"input":"x","stream":false,"return_download_link":true}'
    }

    It 'serialises nested type constructors' {
        $options = New-KokoroNormalizationOption -UnitNormalization -Normalize:$false
        $options.PSObject.TypeNames[0] | Should -Be 'Kokoro.NormalizationOptions'
        $null = New-KokoroSpeech -InputText x -NormalizationOptions $options -OutFile (Join-Path $TestDrive 'b.bin')
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"input":"x","normalization_options":{"normalize":false,"unit_normalization":true}}'
    }

    It 'serialises arrays of constructed objects' {
        $turns = (New-KokoroDialogueTurn -Voice af_bella -Text 'Hi'), (New-KokoroDialogueTurn -Voice am_adam -Text 'Hello')
        $null = New-KokoroDialogue -Turns $turns -PauseBetweenTurns 0.5 -OutFile (Join-Path $TestDrive 'c.bin')
        $global:OpenApiTestCalls[0].Uri | Should -Be 'http://192.168.1.103:8880/dev/dialogue'
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"turns":[{"voice":"af_bella","text":"Hi"},{"voice":"am_adam","text":"Hello"}],"pause_between_turns":0.5}'
    }

    It 'sends a raw array body for string-or-array operations' {
        $null = Join-KokoroVoice -Body 'af_bella', 'af_sky'
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '["af_bella","af_sky"]'
    }

    It 'escapes path segments and builds query strings' {
        $null = Save-KokoroAudioFile -Filename 'a b/c.mp3' -Name 'my file'
        $global:OpenApiTestCalls[0].Uri | Should -Be 'http://192.168.1.103:8880/v1/download/a%20b%2Fc.mp3?name=my%20file'
        $global:OpenApiTestCalls[0].Method | Should -Be 'GET'
        $global:OpenApiTestCalls[0].Body | Should -BeNullOrEmpty
    }

    It 'sends header parameters under their wire name' {
        $null = New-KokoroSpeech -InputText x -XRawResponse 1 -OutFile (Join-Path $TestDrive 'd.bin')
        $global:OpenApiTestCalls[0].Headers['x-raw-response'] | Should -Be '1'
    }

    It 'merges -Headers and passes -TimeoutSec' {
        $null = Test-KokoroHealth -Headers @{ 'X-Extra' = 'yes' } -TimeoutSec 7
        $global:OpenApiTestCalls[0].Headers['X-Extra'] | Should -Be 'yes'
        $global:OpenApiTestCalls[0].Timeout | Should -Be 7
    }

    It 'defaults the timeout to 100 seconds' {
        $null = Test-KokoroHealth
        $global:OpenApiTestCalls[0].Timeout | Should -Be 100
    }

    It 'exposes wire names as parameter aliases and renames reserved names' {
        $parameter = (Get-Command New-KokoroSpeech).Parameters
        $parameter.Keys | Should -Contain 'InputText'
        $parameter.Keys | Should -Not -Contain 'Input'
        $parameter['InputText'].Aliases | Should -Contain 'input'
        $parameter['ResponseFormat'].Aliases | Should -Contain 'response_format'
    }
}

Describe 'Kokoro: validation' {
    BeforeEach { Reset-TestState }

    It 'enforces ranges, enums and requirements before any request' {
        { New-KokoroSpeech -InputText x -Speed 99 } | Should -Throw '*maximum*'
        { New-KokoroSpeech -InputText x -Speed 0.1 } | Should -Throw '*minimum*'
        { New-KokoroSpeech -InputText x -ResponseFormat ogg } | Should -Throw
        { New-KokoroSpeech -InputText x -VolumeMultiplier 11 } | Should -Throw
        { New-KokoroSpeech -InputObject @{ voice = 'x' } } | Should -Throw '*missing required property ''input''*'
        $global:OpenApiTestCalls.Count | Should -Be 0
    }

    It 'rejects a malformed -Endpoint' {
        { Test-KokoroHealth -Endpoint 'not-a-url' } | Should -Throw
    }
}

Describe 'Kokoro: pipeline input' {
    BeforeEach { Reset-TestState }

    It 'accepts a plain string as the primary text property' {
        $null = 'Hello there' | New-KokoroSpeech -OutFile (Join-Path $TestDrive 'p1.bin')
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"input":"Hello there"}'
    }

    It 'streams many strings as many requests' {
        $null = 'one', 'two', 'three' | New-KokoroSpeech
        $global:OpenApiTestCalls.Count | Should -Be 3
        $global:OpenApiTestCalls[2].Body | Should -BeExactly '{"input":"three"}'
    }

    It 'accepts a hashtable using the API property names' {
        $null = @{ input = 'hi'; voice = 'af_bella'; response_format = 'wav' } | New-KokoroSpeech
        $body = $global:OpenApiTestCalls[0].Body | ConvertFrom-Json -AsHashtable
        $body.Keys.Count | Should -Be 3
        $body['input'] | Should -Be 'hi'
        $body['voice'] | Should -Be 'af_bella'
        $body['response_format'] | Should -Be 'wav'
    }

    It 'accepts objects using PowerShell parameter names' {
        $null = [pscustomobject]@{ InputText = 'hi'; ResponseFormat = 'wav'; Speed = 1.5 } | New-KokoroSpeech
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"input":"hi","response_format":"wav","speed":1.5}'
    }

    It 'lets explicit parameters override piped properties' {
        $null = @{ input = 'hi'; voice = 'af_bella' } | New-KokoroSpeech -Voice am_adam
        $body = $global:OpenApiTestCalls[0].Body | ConvertFrom-Json -AsHashtable
        $body['voice'] | Should -Be 'am_adam'
        $body['input'] | Should -Be 'hi'
    }

    It 'rejects a bare string where there is no single required text property' {
        { 'x' | New-KokoroDialogue } | Should -Throw '*bare String*'
    }
}

Describe 'Kokoro: endpoint and credential resolution' {
    BeforeEach { Reset-TestState }

    It 'prefers -Endpoint, then the environment, then the saved setting, then the baked default' {
        $env:KOKORO_ENDPOINT = 'http://env.test:1'
        Set-KokoroDefaultEndpoint 'http://saved.test:2' -Confirm:$false
        $null = Test-KokoroHealth -Endpoint 'http://param.test:3/'
        $global:OpenApiTestCalls[-1].Uri | Should -Be 'http://param.test:3/health'
        $null = Test-KokoroHealth
        $global:OpenApiTestCalls[-1].Uri | Should -Be 'http://env.test:1/health'
        Remove-Item Env:KOKORO_ENDPOINT
        $null = Test-KokoroHealth
        $global:OpenApiTestCalls[-1].Uri | Should -Be 'http://saved.test:2/health'
        Get-KokoroDefaultEndpoint | Should -Be 'http://saved.test:2'
        Clear-KokoroDefaultEndpoint -Confirm:$false
        $null = Test-KokoroHealth
        $global:OpenApiTestCalls[-1].Uri | Should -Be 'http://192.168.1.103:8880/health'
    }

    It 'honours -WhatIf for saving the endpoint' {
        Set-KokoroDefaultEndpoint 'http://saved.test:2' -WhatIf
        $global:OpenApiTestSettingPath | Should -Not -Exist
    }

    It 'sends Basic authentication when an API declares no scheme' {
        $null = Test-KokoroHealth -Credential (New-TestCredential u p)
        $global:OpenApiTestCalls[0].Headers['Authorization'] | Should -Be ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('u:p')))
    }

    It 'sends no Authorization header by default' {
        $null = Test-KokoroHealth
        $global:OpenApiTestCalls[0].Headers | Should -BeNullOrEmpty
    }

    It 'uses a session credential until it is cleared' {
        Set-KokoroCredential (New-TestCredential a b) -Confirm:$false
        $null = Test-KokoroHealth
        $global:OpenApiTestCalls[-1].Headers['Authorization'] | Should -BeLike 'Basic *'
        Set-KokoroCredential -Confirm:$false
        $null = Test-KokoroHealth
        $global:OpenApiTestCalls[-1].Headers | Should -BeNullOrEmpty
    }
}

Describe 'Kokoro: responses' {
    BeforeEach { Reset-TestState }

    It 'parses JSON responses' {
        $global:OpenApiTestResponse = New-FakeResponse -Text '{"object":"list","data":[{"id":"kokoro"}]}'
        $result = Get-KokoroModel
        $result.object | Should -Be 'list'
        $result.data[0].id | Should -Be 'kokoro'
    }

    It 'saves binary responses to a temp file with a matching extension when -OutFile is omitted' {
        $global:OpenApiTestResponse = New-FakeResponse -ContentType 'audio/mpeg' -Bytes ([byte[]](1, 2, 3))
        $global:OpenApiTestResponse.Headers['X-Download-Path'] = '/downloads/x.mp3'
        $result = 'hi' | New-KokoroSpeech
        try
        {
            $result | Should -BeOfType [System.IO.FileInfo]
            $result.Extension | Should -Be '.mp3'
            $result.Name | Should -BeLike 'Kokoro_*'
            $result.ResponseHeaders['X-Download-Path'] | Should -Be '/downloads/x.mp3'
            $result.Length | Should -Be 3
        } finally
        {
            Remove-Item -LiteralPath $result.FullName -ErrorAction SilentlyContinue
        }
    }

    It 'saves into a directory using Content-Disposition' {
        $global:OpenApiTestResponse = New-FakeResponse -ContentType 'audio/wav' -Bytes ([byte[]](9, 9))
        $global:OpenApiTestResponse.Headers['Content-Disposition'] = 'attachment; filename="speech1.wav"'
        $directory = Join-Path $TestDrive 'downloads'
        $null = New-Item -ItemType Directory -Path $directory
        $result = Save-KokoroAudioFile -Filename speech1.wav -OutFile $directory
        $result.FullName | Should -Be (Join-Path $directory 'speech1.wav')
    }

    It 'returns text responses as strings' {
        $global:OpenApiTestResponse = New-FakeResponse -ContentType 'text/plain' -Text 'pong'
        Test-KokoroEndpoint | Should -Be 'pong'
    }

    It 'returns nothing for an empty 204' {
        $global:OpenApiTestResponse = New-FakeResponse -Status 204 -ContentType 'application/json' -Text ''
        Test-KokoroHealth | Should -BeNullOrEmpty
    }

    It 'formats FastAPI validation errors with the failing location' {
        $global:OpenApiTestResponse = New-FakeResponse -Status 422 -Text '{"detail":[{"type":"missing","loc":["body","input"],"msg":"Field required"}]}'
        { 'x' | New-KokoroSpeech } | Should -Throw '*HTTP 422 - body.input: Field required*'
    }

    It 'extracts nested error messages' {
        $global:OpenApiTestResponse = New-FakeResponse -Status 404 -Text '{"detail":{"error":"model_not_found","message":"Model ''x'' not found"}}'
        { Get-KokoroModelById -Model x } | Should -Throw '*HTTP 404 - Model ''x'' not found*'
    }

    It 'reports non-JSON error bodies and includes the failing URL' {
        $global:OpenApiTestResponse = New-FakeResponse -Status 500 -ContentType 'text/html' -Text 'Internal Server Error'
        { Test-KokoroHealth } | Should -Throw '*GET http://192.168.1.103:8880/health - HTTP 500 - Internal Server Error*'
    }

    It 'wraps connection failures with the request URL' {
        Mock Invoke-WebRequest -ModuleName KokoroClient -MockWith { throw 'No connection could be made' }
        { Test-KokoroHealth } | Should -Throw '*API call failed: GET http://192.168.1.103:8880/health - No connection*'
    }
}

Describe 'Pet store (OpenAPI 3.0, server variables, bearer auth)' {
    BeforeEach { Reset-TestState }

    It 'derives the endpoint from the spec server and its variable defaults' {
        $null = Get-PetStorePet
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://pets.example.com/api/v3/pets'
    }

    It 'applies a custom endpoint plus the spec base path' {
        $null = Get-PetStorePet -Endpoint 'https://other.test'
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://other.test/api/v3/pets'
    }

    It 'builds query strings: csv arrays, dotted names, lowercase booleans, escaping' {
        $null = Get-PetStorePet -Limit 5 -Status available, sold -FilterName 'a b' -IncludeDeleted
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://pets.example.com/api/v3/pets?limit=5&status=available,sold&filter.name=a%20b&includeDeleted=true'
    }

    It 'validates generated ranges and enums' {
        { Get-PetStorePet -Limit 0 } | Should -Throw
        { Get-PetStorePet -Limit 101 } | Should -Throw
        { New-PetStorePet -Name '' } | Should -Throw
        { New-PetStorePet -Name ok -Tag 'UPPER' } | Should -Throw
        { New-PetStorePet -Name ok -Status gone } | Should -Throw
    }

    It 'tags typed JSON responses with the schema name' {
        $global:OpenApiTestResponse = New-FakeResponse -Text '[{"id":1,"name":"Rex"},{"id":2,"name":"Tom"}]'
        $pets = @(Get-PetStorePet)
        $pets.Count | Should -Be 2
        $pets[0].PSObject.TypeNames[0] | Should -Be 'PetStore.Pet'
        $pets[1].name | Should -Be 'Tom'
        (Get-Command Get-PetStorePet).OutputType.Name | Should -Be 'PetStore.Pet'
    }

    It 'flattens allOf bodies and sends the required property' {
        $owner = New-PetStoreOwner -Name Pat
        $null = New-PetStorePet -Name Rex -Tag dog -Status sold -Owner $owner
        $global:OpenApiTestCalls[0].Method | Should -Be 'POST'
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"name":"Rex","tag":"dog","status":"sold","owner":{"name":"Pat"}}'
    }

    It 'chains by the Id alias from a pipeline object' {
        $null = [pscustomobject]@{ Id = 5 } | Get-PetStorePetById
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://pets.example.com/api/v3/pets/5'
    }

    It 'maps HEAD to a boolean' {
        $global:OpenApiTestResponse = New-FakeResponse -Status 200 -Text ''
        Test-PetStorePet -PetId 1 | Should -BeTrue
        $global:OpenApiTestCalls[0].Method | Should -Be 'HEAD'
        $global:OpenApiTestResponse = New-FakeResponse -Status 404 -Text ''
        Test-PetStorePet -PetId 2 | Should -BeFalse
        $global:OpenApiTestResponse = New-FakeResponse -Status 500 -Text 'boom'
        { Test-PetStorePet -PetId 3 } | Should -Throw '*HTTP 500*'
        (Get-Command Test-PetStorePet).OutputType.Type | Should -Be ([bool])
    }

    It 'asks for confirmation semantics on DELETE and honours -WhatIf' {
        $global:OpenApiTestResponse = New-FakeResponse -Status 204 -Text ''
        Remove-PetStorePet -PetId 3 -WhatIf
        $global:OpenApiTestCalls.Count | Should -Be 0
        Remove-PetStorePet -PetId 3 -Confirm:$false
        $global:OpenApiTestCalls.Count | Should -Be 1
        $global:OpenApiTestCalls[0].Method | Should -Be 'DELETE'
        (Get-Command Remove-PetStorePet).Parameters.Keys | Should -Contain 'WhatIf'
        (Get-Command New-PetStorePet).Parameters.Keys | Should -Not -Contain 'WhatIf' -Because 'POST creates/computes and does not prompt'
    }

    It 'sends the credential password as a bearer token for the declared http bearer scheme' {
        $null = Get-PetStorePet -Credential (New-TestCredential ignored token123)
        $global:OpenApiTestCalls[0].Headers['Authorization'] | Should -Be 'Bearer token123'
    }

    It 'sends multipart uploads with the file object and string-converted fields' {
        $photo = Join-Path $TestDrive 'pet.jpg'
        Set-Content -LiteralPath $photo -Value 'img'
        $null = Send-PetStorePhoto -PetId 7 -File $photo -Caption 'cap' -IsPrimary
        $call = $global:OpenApiTestCalls[0]
        $call.Uri | Should -Be 'https://pets.example.com/api/v3/pets/7/photo'
        $call.Form['file'] | Should -BeOfType [System.IO.FileInfo]
        $call.Form['file'].FullName | Should -Be (Get-Item -LiteralPath $photo).FullName
        $call.Form['caption'] | Should -Be 'cap'
        $call.Form['isPrimary'] | Should -Be 'true'
        $call.Body | Should -BeNullOrEmpty
        { Send-PetStorePhoto -PetId 7 -File (Join-Path $TestDrive 'missing.jpg') } | Should -Throw
    }

    It 'binds files piped from Get-ChildItem via FullName' {
        $photo = Join-Path $TestDrive 'piped.jpg'
        Set-Content -LiteralPath $photo -Value 'img'
        $null = Get-Item -LiteralPath $photo | Send-PetStorePhoto -PetId 9
        $global:OpenApiTestCalls[0].Form['file'].Name | Should -Be 'piped.jpg'
    }

    It 'handles reserved parameter names and header parameters' {
        $global:OpenApiTestResponse = New-FakeResponse -ContentType 'text/plain' -Text 'echo'
        $tag = New-PetStoreTag -Label l1
        $result = Invoke-PetStoreEchoReport -InputText x -XTraceId t1 -ArgsValue a, b -ErrorValue e -HeadersValue h -Tags $tag
        $result | Should -Be 'echo'
        $global:OpenApiTestCalls[0].Headers['x-trace-id'] | Should -Be 't1'
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"input":"x","args":["a","b"],"error":"e","headers":"h","tags":[{"label":"l1"}]}'
    }

    It 'translates PowerShell names back to wire names when piping an object' {
        $null = [pscustomobject]@{ InputText = 'x'; ArgsValue = 'a' } | Invoke-PetStoreEchoReport
        $global:OpenApiTestCalls[0].Body | Should -BeExactly '{"input":"x","args":"a"}'
    }

    It 'does not create functions for deprecated operations' {
        Get-Command Get-PetStoreOldThing -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'treats a schema constructor as optional-by-default with required properties mandatory' {
        $parameter = (Get-Command New-PetStoreTag).Parameters['Label']
        $parameter.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
        (Get-Command New-PetStoreOwner).Parameters['Email'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeFalse
    }
}

Describe 'Widget service (Swagger 2.0, apiKey security)' {
    BeforeEach { Reset-TestState }

    It 'derives the endpoint from host and basePath and sends enum queries' {
        $null = Get-WidgetWidget -Color red
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://widgets.example.com/v1/widgets?color=red'
        { Get-WidgetWidget -Color green } | Should -Throw
    }

    It 'sends body-parameter schemas as JSON' {
        $null = New-WidgetWidget -Name gizmo -Weight 2
        $global:OpenApiTestCalls[0].Body | Should -Match '^\{"name":"gizmo","weight":2(\.0)?\}$'
        { New-WidgetWidget -Name gizmo -Weight -1 } | Should -Throw
    }

    It 'sends apiKey credentials in the declared header instead of Authorization' {
        $null = Get-WidgetWidget -Credential (New-TestCredential k secret)
        $headers = $global:OpenApiTestCalls[0].Headers
        $headers['X-Key'] | Should -Be 'secret'
        $headers.Keys | Should -Not -Contain 'Authorization'
    }

    It 'converts formData file parameters into multipart uploads' {
        $blueprint = Join-Path $TestDrive 'bp.dxf'
        Set-Content -LiteralPath $blueprint -Value 'x'
        $null = Send-WidgetBlueprint -Id 4 -Blueprint $blueprint -Note n
        $global:OpenApiTestCalls[0].Uri | Should -Be 'https://widgets.example.com/v1/widgets/4/blueprint'
        $global:OpenApiTestCalls[0].Form['blueprint'] | Should -BeOfType [System.IO.FileInfo]
        $global:OpenApiTestCalls[0].Form['note'] | Should -Be 'n'
    }
}
