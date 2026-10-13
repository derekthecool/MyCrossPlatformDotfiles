# OpenAPI client generation

`New-OpenApiClient` turns an OpenAPI 3.0/3.1 (or Swagger 2.0) JSON document into one readable `.ps1` of
PowerShell functions. No AutoRest, no .NET build, no extra modules. The output is deterministic and meant
to be committed.

## Kokoro TTS (the first generated client)

The spec lives in `Source/Kokoro/kokoro_tts_openapi.json`; the output is `Source/Kokoro/Kokoro.ps1`.
Regenerate it (and its block in `DotWebApi.psd1`) with:

```powershell
$root = (Get-Module DotWebApi).ModuleBase   # or the module folder
New-OpenApiClient -Path "$root/Source/Kokoro/kokoro_tts_openapi.json" `
    -OutputPath "$root/Source/Kokoro" -ManifestPath "$root/DotWebApi.psd1" -UpdateManifest `
    -DefaultEndpoint 'http://192.168.1.103:8880' `
    -NameOverride @{
        'POST /dev/phonemize'              = 'ConvertTo-KokoroPhoneme'
        'POST /dev/generate_from_phonemes' = 'New-KokoroSpeechFromPhoneme'
    }
```

A test (`OpenApi.Generation.Tests.ps1`) fails when `Kokoro.ps1` no longer matches the generator output,
so generator changes always come with a regenerated client.

```powershell
'Hello from PowerShell.' | New-KokoroSpeech -Voice af_heart -ResponseFormat wav -OutFile ./hello.wav
Get-KokoroVoice
Get-KokoroModelById -Model kokoro

# Several requests from the pipeline
'one', 'two', 'three' | ForEach-Object { $_ | New-KokoroSpeech -OutFile "./$_.mp3" }
@{ input = 'From a hashtable'; voice = 'af_bella' } | New-KokoroSpeech -OutFile ./h.mp3
[pscustomobject]@{ InputText = 'From an object'; Speed = 1.2 } | New-KokoroSpeech -OutFile ./o.mp3

# Typed helper objects for nested request values
$norm = New-KokoroNormalizationOption -UnitNormalization -RemoveEmoji
New-KokoroSpeech -InputText 'It is 10KB.' -NormalizationOptions $norm -OutFile ./n.mp3
$turns = (New-KokoroDialogueTurn -Voice af_bella -Text 'Hi.'), (New-KokoroDialogueTurn -Voice am_adam -Text 'Hello.')
New-KokoroDialogue -Turns $turns -PauseBetweenTurns 0.3 -OutFile ./talk.mp3
```

Without `-OutFile`, audio is saved to a temp file and returned as a `FileInfo`
(response headers such as `X-Download-Path` are on its `ResponseHeaders` property).

## Endpoint and credentials

Every function accepts `-Endpoint`, `-Credential`, `-Headers`, `-TimeoutSec`.

Endpoint order: `-Endpoint` → `KOKORO_ENDPOINT` environment variable → saved setting
(`Set-KokoroDefaultEndpoint http://host:8880`, stored in `~/.kokoro_config.xml`) → the default baked in with
`-DefaultEndpoint` → the server in the API description. `Get-KokoroDefaultEndpoint` shows the result,
`Clear-KokoroDefaultEndpoint` removes the saved one.

Credentials follow the spec's security scheme: Basic (also used when the spec declares none), `http bearer` /
OAuth2 (password = token) or `apiKey` (header/query/cookie name from the spec). Use `-Credential` per call,
`Set-KokoroCredential (Get-Credential)` for the session, or `Set-KokoroCredential -FromSecret` to read a
SecretManagement secret (`<Prefix>ApiKey`) once. Nothing reads a vault implicitly, so commands never prompt
for a vault password.

## How operations become commands

* **Verb**: first word of the summary (else operationId) via a synonym table (`create`→`New`, `list`/`get`/`retrieve`→`Get`,
  `download`→`Save`, `combine`→`Join`, `check`/`health`→`Test`, …), then the HTTP method. Only approved verbs.
  `-VerbMap @{ word = 'Verb' }` adds mappings.
* **Noun**: rest of the text, singular, prefixed (`Get-KokoroVoice`). Duplicates become `…ById`, then the method.
  `-NameOverride @{ 'POST /path' = 'Verb-Noun' }` (or by operationId) fixes outliers; the run prints what it disambiguated.
* **Parameters**: path/query/header values and the top-level properties of a JSON body. Types, `ValidateSet`,
  ranges, lengths and (case-sensitive) patterns come from the schema. Only parameters you pass are sent, so server
  defaults apply. Reserved names are renamed (`input` → `-InputText`, alias `-input` still works).
* **Pipeline**: path/query/header parameters bind by property name (the last path parameter also answers to `Id`).
  Body operations take a hashtable, object or (for one required text property) plain string through `-InputObject`;
  keys may be API names or PowerShell parameter names and explicit parameters override them.
* **Types**: named object schemas used in requests get `New-<Prefix><Type>` constructors tagged `<Prefix>.<Type>`;
  typed JSON responses are tagged the same way. (No PowerShell classes: they do not survive dot-sourcing into a module.)
* **Responses** are read by their real `Content-Type`, not the spec (Kokoro declares audio endpoints as JSON):
  JSON is parsed, text returned, anything else saved to `-OutFile`/temp. `HEAD` operations return `[bool]`.
  HTTP errors throw with the server's message (FastAPI `detail[]` locations included).
* DELETE/PUT/PATCH support `-WhatIf`/`-Confirm`. Multipart uploads take a file path (`-File`, pipeline `FullName`).

## Using it in another module

`-OutputPath` can be any directory or `.ps1` path, and `-ManifestPath` any `.psd1`:

```powershell
New-OpenApiClient -Path ./petstore.json -OutputPath ~/work/MyModule/Source/PetStore `
    -ManifestPath ~/work/MyModule/MyModule.psd1 -UpdateManifest
```

Outside DotWebApi the request runtime is copied next to the client as `private/<Name>.Runtime.ps1`
(`-RuntimeMode Embedded`, chosen automatically), so the output has no DotWebApi dependency.
Inside DotWebApi (`-RuntimeMode Module`) it uses the shared runtime in `Source/OpenApiGeneration/private`.
Keep a `private` folder out of your own export scan if you use one.

### Manifest exports

Lazy loading needs explicit `FunctionsToExport`. `-UpdateManifest` (or `Update-ModuleManifestExport` on its own)
rewrites only the array text between `# BEGIN generated: <Name>` / `# END generated: <Name>` markers, leaving
hand-written entries and comments alone; re-running replaces just that block, so removed operations drop out.
`Update-ModuleManifestExport -Full` instead replaces the whole arrays from an AST scan of `-SourcePath`
(adapted from the FreeusPowershell psakefile, `private` folders skipped). Do not run `-Full` against DotWebApi
unless its unexported helpers live under a `private` folder.

## Limits

* Local `$ref`s only; external files are not followed.
* OAuth2 token acquisition is not automatic (pass the token as the credential password).
* Cookie parameters, callbacks and webhooks are ignored; `oneOf`/`anyOf` of several object types become `[object]`.
* Swagger 2.0 support is best-effort; 3.0.x and 3.1 are the supported scope. YAML needs `ConvertFrom-Yaml`.

## Tests

`Test/OpenApiGeneration/` (Pester): parser, naming, manifest editing, generation/determinism/portability,
behaviour with a mocked `Invoke-WebRequest`, and live Kokoro tests that skip themselves when the server
(`http://192.168.1.103:8880`, or `$env:KOKORO_ENDPOINT`) is unreachable.
