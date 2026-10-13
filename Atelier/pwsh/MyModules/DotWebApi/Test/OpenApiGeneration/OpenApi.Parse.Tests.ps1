BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
    $fixtures = Join-Path $PSScriptRoot 'Fixtures'
}

Describe 'Import-OpenApiDocument' {
    It 'loads an OpenAPI 3.1 document and hashes the raw file' {
        $path = Join-Path $moduleRoot 'Source/Kokoro/kokoro_tts_openapi.json'
        $result = InModuleScope DotWebApi -Parameters @{ Path = $path } { Import-OpenApiDocument -Path $Path }
        $result.Document.openapi | Should -Match '^3\.1'
        $result.Document.info.title | Should -Be 'Kokoro TTS API'
        $result.Sha256 | Should -Be (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        $result.SourceName | Should -Be 'kokoro_tts_openapi.json'
    }

    It 'rejects a document without a version field' {
        $path = Join-Path $TestDrive 'bad.json'
        Set-Content -LiteralPath $path -Value '{ "paths": {} }'
        { InModuleScope DotWebApi -Parameters @{ Path = $path } { Import-OpenApiDocument -Path $Path } } | Should -Throw '*neither an ''openapi'' nor a ''swagger''*'
    }

    It 'reports a missing file' {
        { InModuleScope DotWebApi { Import-OpenApiDocument -Path 'nope/missing.json' } } | Should -Throw '*not found*'
    }

    It 'normalises Swagger 2.0 to the 3.x shape' {
        $path = Join-Path $fixtures 'widgets.swagger2.json'
        $doc = (InModuleScope DotWebApi -Parameters @{ Path = $path } { Import-OpenApiDocument -Path $Path }).Document
        $doc.openapi | Should -Be '3.0.3'
        $doc.servers[0].url | Should -Be 'https://widgets.example.com/v1'
        $doc.components.schemas.Keys | Should -Contain 'Widget'
        $doc.components.securitySchemes.key.type | Should -Be 'apiKey'
        $create = $doc.paths['/widgets'].post
        $create.requestBody.content['application/json'].schema['$ref'] | Should -Be '#/components/schemas/Widget'
        $upload = $doc.paths['/widgets/{id}/blueprint'].post
        $upload.requestBody.content.Keys | Should -Contain 'multipart/form-data'
        $upload.requestBody.content['multipart/form-data'].schema.properties.blueprint.format | Should -Be 'binary'
    }
}

Describe 'Resolve-OpenApiReference' {
    It 'resolves local pointers and unescapes segments' {
        InModuleScope DotWebApi {
            $doc = @{ components = @{ schemas = @{ 'a/b' = @{ type = 'string' } } } }
            (Resolve-OpenApiReference -Document $doc -Reference '#/components/schemas/a~1b').type | Should -Be 'string'
        }
    }

    It 'throws for missing and external references' {
        InModuleScope DotWebApi {
            { Resolve-OpenApiReference -Document @{} -Reference '#/components/schemas/Nope' } | Should -Throw '*could not be resolved*'
            { Resolve-OpenApiReference -Document @{} -Reference 'other.json#/x' } | Should -Throw '*local references*'
        }
    }
}

Describe 'Get-OpenApiTypeInfo' {
    BeforeAll {
        $script:petstore = (InModuleScope DotWebApi -Parameters @{ Path = (Join-Path $fixtures 'petstore.v3.json') } { Import-OpenApiDocument -Path $Path }).Document
        $script:kokoro = (InModuleScope DotWebApi -Parameters @{ Path = (Join-Path $moduleRoot 'Source/Kokoro/kokoro_tts_openapi.json') } { Import-OpenApiDocument -Path $Path }).Document
    }

    It 'treats anyOf [T, null] as a nullable T and keeps wrapper description and default' {
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $script:kokoro } {
            Get-OpenApiTypeInfo -Document $Doc -Schema $Doc.components.schemas.OpenAISpeechRequest.properties.volume_multiplier
        }
        $info.Kind | Should -Be 'number'
        $info.Nullable | Should -BeTrue
        $info.Minimum | Should -Be 0
        $info.Maximum | Should -Be 10
        $info.HasDefault | Should -BeTrue
        $info.Description | Should -Match 'volume multiplier'
    }

    It 'keeps a zero minimum (falsy values are still facets)' {
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $script:kokoro } {
            Get-OpenApiTypeInfo -Document $Doc -Schema $Doc.components.schemas.OpenAISpeechRequest.properties.volume_multiplier
        }
        $info.Minimum | Should -Not -BeNullOrEmpty -Because '0 is a real minimum'
        $info.Minimum | Should -Be 0
    }

    It 'maps string-or-array-of-string to an array flagged ScalarOrArray' {
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $script:kokoro } {
            $schema = $Doc.paths['/v1/audio/voices/combine'].post.requestBody.content['application/json'].schema
            Get-OpenApiTypeInfo -Document $Doc -Schema $schema
        }
        $info.Kind | Should -Be 'array'
        $info.Items.Kind | Should -Be 'string'
        $info.ScalarOrArray | Should -BeTrue
    }

    It 'follows a $ref and records the schema name' {
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $script:kokoro } {
            Get-OpenApiTypeInfo -Document $Doc -Schema $Doc.components.schemas.OpenAISpeechRequest.properties.normalization_options
        }
        $info.Kind | Should -Be 'object'
        $info.RefName | Should -Be 'NormalizationOptions'
        $info.Properties.Keys | Should -Contain 'unit_normalization'
    }

    It 'detects binary uploads as file' {
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $script:kokoro } {
            Get-OpenApiTypeInfo -Document $Doc -Schema $Doc.components.schemas.Body_tune_speech_dev_tune_post.properties.audio
        }
        $info.Kind | Should -Be 'file'
    }

    It 'merges allOf parts and terminates on recursive schemas' {
        $info = InModuleScope DotWebApi -Parameters @{ Doc = $script:petstore } {
            Get-OpenApiTypeInfo -Document $Doc -Schema @{ '$ref' = '#/components/schemas/Pet' }
        }
        $info.Kind | Should -Be 'object'
        $info.Properties.Keys | Should -Contain 'name'
        $info.Properties.Keys | Should -Contain 'id'
        $info.Required | Should -Contain 'name'
        $info.Required | Should -Contain 'id'
        $info.Properties['children'].Kind | Should -Be 'array'
        $info.Properties['children'].Items.RefName | Should -Be 'Pet'
        $info.Properties['owner'].Properties['parent'].Kind | Should -Be 'object' -Because 'a recursive reference becomes an opaque object'
    }

    It 'understands 3.1 type arrays and 3.0 nullable' {
        InModuleScope DotWebApi {
            $a = Get-OpenApiTypeInfo -Document @{} -Schema @{ type = @('string', 'null') }
            $a.Kind | Should -Be 'string'
            $a.Nullable | Should -BeTrue
            $b = Get-OpenApiTypeInfo -Document @{} -Schema @{ type = 'integer'; nullable = $true; format = 'int64' }
            $b.Kind | Should -Be 'integer'
            $b.Nullable | Should -BeTrue
            $b.Format | Should -Be 'int64'
        }
    }

    It 'returns an any-typed model for an empty schema' {
        InModuleScope DotWebApi {
            (Get-OpenApiTypeInfo -Document @{} -Schema @{}).Kind | Should -Be 'any'
            (Get-OpenApiTypeInfo -Document @{} -Schema $null).Kind | Should -Be 'any'
        }
    }
}

Describe 'Get-OpenApiOperation' {
    It 'merges path-level parameters into each operation and sorts deterministically' {
        $doc = (InModuleScope DotWebApi -Parameters @{ Path = (Join-Path $fixtures 'petstore.v3.json') } { Import-OpenApiDocument -Path $Path }).Document
        $ops = InModuleScope DotWebApi -Parameters @{ Doc = $doc } { @(Get-OpenApiOperation -Document $Doc) }
        $keys = $ops | ForEach-Object { "$($_.Method) $($_.Path)" }
        $keys | Should -Contain 'GET /pets/{petId}'
        $keys | Should -Contain 'HEAD /pets/{petId}'
        ($ops | Where-Object { $_.Method -eq 'DELETE' }).Parameters.name | Should -Contain 'petId'
        $paths = $ops.Path
        $paths | Should -Be @($paths | Sort-Object)
    }
}
