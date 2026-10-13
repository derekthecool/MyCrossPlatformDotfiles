BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
    $fixtures = Join-Path $PSScriptRoot 'Fixtures'
}

Describe 'Get-OpenApiVerbNoun' {
    It '<Method> <Path> (<Summary> / <OperationId>) -> <Verb>-<Noun>' -ForEach @(
        @{ Method = 'POST'; Path = '/v1/audio/speech'; Summary = 'Create Speech'; OperationId = 'create_speech_v1_audio_speech_post'; Verb = 'New'; Noun = 'Speech' }
        @{ Method = 'GET'; Path = '/v1/models'; Summary = 'List Models'; OperationId = 'list_models_v1_models_get'; Verb = 'Get'; Noun = 'Model' }
        @{ Method = 'GET'; Path = '/v1/audio/voices'; Summary = 'List Voices'; OperationId = 'list_voices_v1_audio_voices_get'; Verb = 'Get'; Noun = 'Voice' }
        @{ Method = 'POST'; Path = '/v1/audio/voices/combine'; Summary = 'Combine Voices'; OperationId = 'combine_voices_v1_audio_voices_combine_post'; Verb = 'Join'; Noun = 'Voice' }
        @{ Method = 'GET'; Path = '/v1/download/{filename}'; Summary = 'Download Audio File'; OperationId = 'download_audio_file_v1_download__filename__get'; Verb = 'Save'; Noun = 'AudioFile' }
        @{ Method = 'GET'; Path = '/health'; Summary = 'Health Check'; OperationId = 'health_check_health_get'; Verb = 'Test'; Noun = 'Health' }
        @{ Method = 'POST'; Path = '/dev/reload'; Summary = 'Reload Model'; OperationId = 'reload_model_dev_reload_post'; Verb = 'Update'; Noun = 'Model' }
        @{ Method = 'POST'; Path = '/dev/unload'; Summary = 'Unload Model'; OperationId = 'unload_model_dev_unload_post'; Verb = 'Unregister'; Noun = 'Model' }
        @{ Method = 'POST'; Path = '/dev/tune'; Summary = 'Tune Speech'; OperationId = 'tune_speech_dev_tune_post'; Verb = 'Optimize'; Noun = 'Speech' }
        @{ Method = 'POST'; Path = '/dev/ssml'; Summary = 'Translate Ssml Text'; OperationId = 'translate_ssml_text_dev_ssml_post'; Verb = 'ConvertTo'; Noun = 'SsmlText' }
        @{ Method = 'GET'; Path = '/dev/ssml'; Summary = 'Ssml Capabilities'; OperationId = 'ssml_capabilities_dev_ssml_get'; Verb = 'Get'; Noun = 'SsmlCapability' }
        @{ Method = 'GET'; Path = '/dev/model'; Summary = 'Model Status'; OperationId = 'model_status_dev_model_get'; Verb = 'Get'; Noun = 'ModelStatus' }
        @{ Method = 'GET'; Path = '/debug/system'; Summary = 'Get System Info'; OperationId = 'get_system_info_debug_system_get'; Verb = 'Get'; Noun = 'SystemInfo' }
        @{ Method = 'POST'; Path = '/dev/phonemize'; Summary = 'Phonemize Text'; OperationId = 'phonemize_text_dev_phonemize_post'; Verb = 'Invoke'; Noun = 'PhonemizeText' }
        @{ Method = 'GET'; Path = '/v1/chains'; Summary = 'Chain List'; OperationId = 'ListChains'; Verb = 'Get'; Noun = 'Chain' }
        @{ Method = 'HEAD'; Path = '/v1/chains/{name}'; Summary = 'Chain Exists'; OperationId = 'ChainExists'; Verb = 'Test'; Noun = 'Chain' }
        @{ Method = 'GET'; Path = '/v1/locations/{id}'; Summary = ''; OperationId = 'LocationsGetByID'; Verb = 'Get'; Noun = 'Location' }
        @{ Method = 'GET'; Path = '/pets'; Summary = 'List all pets'; OperationId = 'listPets'; Verb = 'Get'; Noun = 'Pet' }
        @{ Method = 'POST'; Path = '/pets'; Summary = 'Create a pet'; OperationId = 'createPet'; Verb = 'New'; Noun = 'Pet' }
        @{ Method = 'DELETE'; Path = '/pets/{petId}'; Summary = ''; OperationId = ''; Verb = 'Remove'; Noun = 'Pet' }
        @{ Method = 'PUT'; Path = '/things/{id}'; Summary = ''; OperationId = ''; Verb = 'Set'; Noun = 'Thing' }
    ) {
        $result = InModuleScope DotWebApi -Parameters @{ M = $Method; P = $Path; S = $Summary; O = $OperationId } {
            Get-OpenApiVerbNoun -Path $P -Method $M -Summary $S -OperationId $O
        }
        $result.Verb | Should -BeExactly $Verb
        $result.Noun | Should -BeExactly $Noun
    }

    It 'honours -VerbMap for the leading word' {
        $result = InModuleScope DotWebApi {
            Get-OpenApiVerbNoun -Path '/x' -Method POST -Summary 'Phonemize Text' -VerbMap @{ phonemize = 'ConvertTo' }
        }
        $result.Verb | Should -Be 'ConvertTo'
        $result.Noun | Should -Be 'Text'
    }
}

Describe 'Get-OpenApiSingularWord' {
    It '<Word> -> <Expected>' -ForEach @(
        @{ Word = 'Models'; Expected = 'Model' }
        @{ Word = 'Voices'; Expected = 'Voice' }
        @{ Word = 'Capabilities'; Expected = 'Capability' }
        @{ Word = 'Addresses'; Expected = 'Address' }
        @{ Word = 'Boxes'; Expected = 'Box' }
        @{ Word = 'Status'; Expected = 'Status' }
        @{ Word = 'Alias'; Expected = 'Alias' }
        @{ Word = 'Info'; Expected = 'Info' }
        @{ Word = 'Cat'; Expected = 'Cat' }
    ) {
        InModuleScope DotWebApi -Parameters @{ W = $Word; E = $Expected } { Get-OpenApiSingularWord -Word $W | Should -BeExactly $E }
    }
}

Describe 'ConvertTo-OpenApiParameterName' {
    It '<Wire> -> <Expected>' -ForEach @(
        @{ Wire = 'input'; Expected = 'InputText' }
        @{ Wire = 'x-raw-response'; Expected = 'XRawResponse' }
        @{ Wire = 'filter.zipCode.near'; Expected = 'FilterZipCodeNear' }
        @{ Wire = 'voice_aliases'; Expected = 'VoiceAliases' }
        @{ Wire = 'Error'; Expected = 'ErrorValue' }
        @{ Wire = 'args'; Expected = 'ArgsValue' }
        @{ Wire = 'headers'; Expected = 'HeadersValue' }
        @{ Wire = 'endpoint'; Expected = 'EndpointValue' }
        @{ Wire = 'verbose'; Expected = 'VerboseValue' }
        @{ Wire = '3d'; Expected = 'P3d' }
        @{ Wire = 'petId'; Expected = 'PetId' }
    ) {
        InModuleScope DotWebApi -Parameters @{ W = $Wire; E = $Expected } { ConvertTo-OpenApiParameterName -WireName $W | Should -BeExactly $E }
    }
}

Describe 'Get-OpenApiClientName' {
    It '<Title> -> <Expected>' -ForEach @(
        @{ Title = 'Kokoro TTS API'; Expected = 'Kokoro' }
        @{ Title = 'Pet Store REST API'; Expected = 'PetStore' }
        @{ Title = 'Location API'; Expected = 'Location' }
        @{ Title = 'Authorization Endpoints'; Expected = 'Authorization' }
        @{ Title = 'Swagger Petstore'; Expected = 'Petstore' }
        @{ Title = ''; Expected = 'Api' }
    ) {
        InModuleScope DotWebApi -Parameters @{ T = $Title; E = $Expected } { Get-OpenApiClientName -Title $T | Should -BeExactly $E }
    }
}

Describe 'Resolve-OpenApiFunctionName' {
    It 'names the Kokoro API with approved, unique, deterministic names' {
        $names = InModuleScope DotWebApi -Parameters @{ Spec = (Join-Path $moduleRoot 'Source/Kokoro/kokoro_tts_openapi.json') } {
            $doc = (Import-OpenApiDocument -Path $Spec).Document
            $records = @(foreach ($o in Get-OpenApiOperation -Document $doc)
                {
                    [pscustomobject]@{ Path = $o.Path; Method = $o.Method; Summary = [string]$o.Operation['summary']; OperationId = [string]$o.Operation['operationId']; Name = $null }
                })
            $named = Resolve-OpenApiFunctionName -Operation $records -Prefix Kokoro
            [pscustomobject]@{ Name = @($named.Name); Verb = @($named.Verb); Approved = @((Get-Verb).Verb) }
        }
        $names.Name.Count | Should -Be 23
        @($names.Name | Select-Object -Unique).Count | Should -Be 23
        foreach ($verb in $names.Verb)
        {
            $verb | Should -BeIn $names.Approved
        }
        $names.Name | Should -Contain 'New-KokoroSpeech'
        $names.Name | Should -Contain 'Get-KokoroModel'
        $names.Name | Should -Contain 'Get-KokoroModelById'
        $names.Name | Should -Contain 'Get-KokoroVoice'
        $names.Name | Should -Contain 'Join-KokoroVoice'
        $names.Name | Should -Contain 'Save-KokoroAudioFile'
        $names.Name | Should -Contain 'Test-KokoroHealth'
        $names.Name | Should -Contain 'Optimize-KokoroSpeech'
    }

    It 'applies NameOverride by METHOD /path and by operationId' {
        $names = InModuleScope DotWebApi -Parameters @{ Spec = (Join-Path $moduleRoot 'Source/Kokoro/kokoro_tts_openapi.json') } {
            $doc = (Import-OpenApiDocument -Path $Spec).Document
            $records = @(foreach ($o in Get-OpenApiOperation -Document $doc)
                {
                    [pscustomobject]@{ Path = $o.Path; Method = $o.Method; Summary = [string]$o.Operation['summary']; OperationId = [string]$o.Operation['operationId']; Name = $null }
                })
            $overrides = @{ 'POST /dev/phonemize' = 'ConvertTo-KokoroPhoneme'; 'health_check_health_get' = 'Test-KokoroServer' }
            @((Resolve-OpenApiFunctionName -Operation $records -Prefix Kokoro -NameOverride $overrides).Name)
        }
        $names | Should -Contain 'ConvertTo-KokoroPhoneme'
        $names | Should -Contain 'Test-KokoroServer'
        $names | Should -Not -Contain 'Test-KokoroHealth'
    }

    It 'disambiguates same-named operations (ById, then method, then number)' {
        $names = InModuleScope DotWebApi {
            $records = @(
                [pscustomobject]@{ Path = '/a'; Method = 'GET'; Summary = 'List Things'; OperationId = ''; Name = $null }
                [pscustomobject]@{ Path = '/a/{id}'; Method = 'GET'; Summary = 'Get Thing'; OperationId = ''; Name = $null }
                [pscustomobject]@{ Path = '/b/{id}'; Method = 'GET'; Summary = 'Get Thing'; OperationId = ''; Name = $null }
            )
            @((Resolve-OpenApiFunctionName -Operation $records -Prefix X).Name)
        }
        $names | Should -Contain 'Get-XThing'
        $names | Should -Contain 'Get-XThingById'
        @($names | Select-Object -Unique).Count | Should -Be 3
    }

    It 'avoids names reserved for the per-API endpoint/credential helpers' {
        $names = InModuleScope DotWebApi {
            $records = @([pscustomobject]@{ Path = '/endpoint'; Method = 'PUT'; Summary = 'Set Default Endpoint'; OperationId = ''; Name = $null })
            @((Resolve-OpenApiFunctionName -Operation $records -Prefix X -ReservedName 'Set-XDefaultEndpoint').Name)
        }
        $names | Should -Not -Contain 'Set-XDefaultEndpoint'
    }
}
