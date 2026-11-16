# OpenAPI client generation

`New-OpenApiClient` turns an OpenAPI 3.0/3.1 (or Swagger 2.0) document, JSON or YAML, into one readable `.ps1` of
PowerShell functions. No AutoRest, no .NET build. The output is deterministic and meant to be committed. YAML specs
need the `powershell-yaml` module (`ConvertFrom-Yaml`), which `Atelier/pwsh/Bootstrap-RequiredModules.ps1` installs.

## Clients committed in DotWebApi

| Client          | Commands                                                                                                                              | Spec                                                             | Default endpoint                              |
|-----------------|---------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|-----------------------------------------------|
| Kokoro TTS      | `*-Kokoro*`                                                                                                                           | `Source/Kokoro/kokoro_tts_openapi.json`                          | `http://192.168.1.103:8880`                   |
| Frigate NVR     | `*-Frigate*` (194 operations)                                                                                                         | `Source/Frigate/frigate-api.yaml`                                | `http://192.168.1.91:5000` (spec adds `/api`) |
| Open Food Facts | `*-OpenFoodFacts*`                                                                                                                    | `Source/OpenFoodFacts/spec/api.yaml` plus the files it refers to | `https://world.openfoodfacts.org`             |
| Open-Meteo      | `Get-OpenMeteoForecast`, `…AirQuality`, `…Climate`, `…Elevation`, `…Ensemble`, `…Flood`, `…HistoricalWeather`, `…Marine`, `…Seasonal` | `Source/OpenMeteo/spec/*.yml`                                    | one host per API, from the spec               |

`examples/GeneratedClients.psd1` is the single table of what is generated (spec, output folder, default endpoint,
`-NameOverride`s, where the spec came from and its licence). Regenerate from it, which also rewrites each client's
`# BEGIN/END generated` block in `DotWebApi.psd1`:

```powershell
./examples/Update-GeneratedClients.ps1                    # everything
./examples/Update-GeneratedClients.ps1 -Name Frigate      # one client (wildcards work)
./examples/Update-GeneratedClients.ps1 -Check             # change nothing, fail if a committed file is out of date
```

`OpenApi.GeneratedClients.Tests.ps1` does the same check for every row of the table (plus exports, approved verbs and
PSScriptAnalyzer), so generator changes always come with regenerated clients. Open-Meteo publishes one spec per API, each on its
own host, so each is its own client (`Get-OpenMeteoMarineDefaultEndpoint`, `Set-OpenMeteoMarineDefaultEndpoint`, …); the
second server in each spec is the paid customer host and takes an `-Apikey`. Open Food Facts asks apps to send a
descriptive `User-Agent` (`-Headers @{ 'User-Agent' = 'MyApp/1.0 (me@example.com)' }`); production and staging
(`https://world.openfoodfacts.net`) are `-Endpoint` choices. Frigate's default is `http://192.168.1.91:5000`;
`Set-FrigateDefaultEndpoint` or `FRIGATE_ENDPOINT` points it elsewhere without regenerating.

A spec that is not in the table is one call:

```powershell
$root = (Get-Module DotWebApi).ModuleBase
New-OpenApiClient -Path "$root/Source/Kokoro/kokoro_tts_openapi.json" -OutputPath "$root/Source/Kokoro" `
    -ManifestPath "$root/DotWebApi.psd1" -UpdateManifest -DefaultEndpoint 'http://192.168.1.103:8880'
```

## Kokoro TTS (the first generated client)

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
`Set-KokoroCredential (Get-Credential)` for the session, or `Set-KokoroCredential -FromSecret [-SecretName X]` to read a
SecretManagement secret (default `<Prefix>ApiKey`, the same name a hand-written `Connect-<Name>` would use) once. Nothing reads
a vault implicitly, so commands never prompt for a vault password.

Two real-world conventions are handled for you:

* Swagger 2.0 has no bearer type, so swaggo (Go) services declare `apiKey` in the `Authorization` header and expect
  `Bearer <token>`. A bare token gets the `Bearer` prefix; a value that already has a scheme is left alone.
* Custom key headers often say "Enter: apikey {your-token}" while the service wants the bare token (an AutoRest-era API).
  A pasted `apikey` prefix is stripped for any `apiKey` header other than `Authorization`.

## How operations become commands

* **Verb**: first word of the summary (else operationId) via a synonym table (`create`→`New`, `list`/`get`/`retrieve`→`Get`,
  `download`→`Save`, `combine`→`Join`, `check`/`health`→`Test`, `readmit`→`Restore`, `force`→`Invoke`, …), then the HTTP method.
  Only approved verbs. `-VerbMap @{ word = 'Verb' }` adds mappings.
* **Noun**: rest of the text, singular, then `-Prefix` in front (`-Prefix Nice` gives `Get-NiceObject`; use it to keep two APIs
  that both have a plain `Get-Object` apart, or to stay clear of an older module). Prepositional tails are dropped
  ("Add devices **to inventory**" → `Add-VpnDevice`), and a noun that only repeats the verb is dropped (`Restart-Frigate`,
  `New-FrigateUser` for "Create new user"). Two operations that want the same name are ordered shortest path first, which keeps the
  plain name; the rest try, in order, `…ById` (the key is the resource id) or `…By<Key>` (`Get-FleetProgramByHostname`), the path
  words the noun lacks (`/debug_replay/start_from_export` → `Start-FrigateDebugReplayFromExport`, `/thumbnail.webp` →
  `…ThumbnailWebp`), `…By<FirstKey>` when the path starts with a parameter (`Get-FrigateRecordingsSummaryByCameraName`), the HTTP
  method name, then a number. `-NameOverride @{ 'POST /path' = 'Verb-Noun' }` (or by operationId) fixes outliers; the run prints
  what it disambiguated. `-ReservedName` lists commands that must not be generated.
* **Specs with no summary and no operationId** (ASP.NET Core/Swashbuckle) are named from the route: `api` and `v1` segments
  are dropped, segments become the singular noun, a trailing action segment is the verb (`POST /api/devices/search` →
  `Search-FleetDevice`), otherwise the method is (`GET` Get, `POST` New, `PUT` Set, `PATCH` Update, `DELETE` Remove).
* **Method-style operationIds** (`PostBulkAssignAsyncPut`, `GetSearchdeviceByDeviceid`, common after AutoRest era) drop the
  leading HTTP-method word; `POST` then becomes `Invoke-` (AutoRest's choice too), keeping trailing echoes so
  `…SubscriberAsyncGet/Put/Del` stay distinct (`Invoke-GadgetBulkSubscriberAsyncPut`).
* **Parameters**: path/query/header values and the top-level properties of a JSON body. Types, `ValidateSet`,
  ranges, lengths and (case-sensitive) patterns come from the schema. Only parameters you pass are sent, so server
  defaults apply. Reserved names are renamed (`input` → `-InputText`, alias `-input` still works). Password fields
  (`password`, `old_password`, …, or `format: password`) are `[securestring]` parameters; the generated code converts them to
  text only when it builds the request, and a SecureString inside `-InputObject` is converted too.
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
(adapted from a psakefile task, `private` folders skipped). Do not run `-Full` against DotWebApi
unless its unexported helpers live under a `private` folder.

## Several APIs in one module

Give every client in the module the same `-RuntimeName` and they share one runtime (`private/<RuntimeName>.Runtime.ps1`,
functions `Invoke-<RuntimeName>ApiRequest`, …) instead of one copy each; regenerating an identical runtime leaves the file
untouched. Each client keeps its own endpoint/credential helpers keyed by its `-Prefix`.

```powershell
$common = @{ OutputPath = "$module/source"; ManifestPath = "$module/MyModule.psd1"; UpdateManifest = $true; RuntimeName = 'My' }
New-OpenApiClient @common -Path ./fleet.json   -Name FleetManager -Prefix Fleet -DefaultEndpoint http://host:5010
New-OpenApiClient @common -Path ./registry.json -Name PeerRegistry -Prefix Peer  -DefaultEndpoint http://host:1900
New-OpenApiClient @common -Path ./gadget.json  -Name Gadget -Prefix Gadget -ReservedName (Import-PowerShellDataFile $old.psd1).FunctionsToExport
```

**The target repository never depends on the generator.** Generated files carry only "generated code, do not edit", the source
spec name and its SHA-256, never the generator's name, and the embedded runtime is a plain copy with its developer notes
removed. Nothing in the target needs DotWebApi to load, run, build or publish. Only regenerating does, and the repository that
owns the spec keeps its own small regeneration script (a few `New-OpenApiClient` calls with that API's name, prefix and
default endpoint) that imports DotWebApi when it is available and stops with a clear message when it is not. Generator
knowledge about a particular service does not belong in this repository. A test enforces the generated side: no generated file
may mention `DotWebApi`, `New-OpenApiClient` or the other generator commands, and the module may not call any command that
only the generator provides.

The layout is meant for builds that concatenate `source/**/*.ps1` (sorted by file name) into one psm1 and rebuild
`FunctionsToExport` from an AST scan that skips `private`, so the runtime stays unexported and the manifest region and the
build agree. When such a build has already rewritten the manifest (bare `FunctionsToExport = 'a', 'b'` lists, no region
markers), regenerating leaves it untouched if it already names everything. Catch-all routes (`…/proxy/{path}`) keep their slashes:
a trailing path parameter named `path`, `filepath`, `catchall`, `rest`, `wildcard` or `remainder` is sent unescaped between
slashes, and `-RawPathParameter name` does the same for any other name.

## Lessons learned from real specs

| Spec                                         | What it taught the generator                                                                                                                                                                                                                                      |
|----------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Kokoro (FastAPI, 3.1)                        | Responses are declared JSON but are audio → decide by real `Content-Type`; `input` collides with `$input`; `anyOf [T, null]`.                                                                                                                                     |
| Kroger (3.0.3)                               | OAuth2 schemes, `HEAD` operations, dotted parameter names, summaries that name worse than operationIds → score every naming source.                                                                                                                               |
| Pet store fixture                            | Server variables, bearer auth, recursion/`allOf`, multipart, CSV array queries, case-sensitive patterns (`ValidatePattern` ignores case unless `Options = 'None'`).                                                                                               |
| ASP.NET Core service (3.0.4)                 | No summaries/operationIds → route-based names; catch-all proxy route; `text/plain`+`application/json` duplicates; no `servers`.                                                                                                                                   |
| swaggo service (Swagger 2.0)                 | `Authorization` apiKey needs `Bearer`; `host` without `schemes` (localhost → http); `-ReservedName`, prepositional summaries.                                                                                                                                     |
| AutoRest-era service (3.0.4, 108 operations) | Method-style operationIds, `ApiKey` header with "apikey " text, spec `servers`, 140 commands that must not clash with an existing AutoRest module's.                                                                                                              |
| Frigate (FastAPI, YAML, 194 operations)      | YAML input; many near-duplicate names (`/events` vs `/event_ids`, `.jpg` vs `.webp`) → shortest path wins and path words disambiguate instead of `Get`/`Post` suffixes; `Restart-FrigateRestart`; `username`/`password` fields → SecureString (PSScriptAnalyzer). |
| Open Food Facts (3.1, 79 files)              | A spec split over files with relative `$ref`s (whole-file and pointer, nested, self-referencing) → folded into one document with a combined hash; examples are not followed; production vs staging in `servers`.                                                  |
| Open-Meteo (3.1, 9 specs)                    | Servers declared only on the path item; one spec and host per API; a `latitude` that is a comma-separated string, not an array.                                                                                                                                   |

Smaller rules that came out of it: a parse error in any module source file stops the module from loading (the loader
dot-sources everything); the manifest updater must not require a built `psm1` and reverts if its result is invalid; empty
`.Keys` loops need guards (`@($null.Keys)` iterates once); `-WhatIf` runs of the generator still validate and name everything.

## Limits

* External `$ref`s (relative files or http(s) URLs) are folded into the document for 3.x specs: a target under
  `#/components/<kind>/<name>` keeps that kind and name, a whole-file reference is filed by position (parameter, response,
  request body, header, schema) under a name taken from the file, clashes get a numeric suffix, and `example`/`examples` are not
  followed. The `SHA256` in the generated header then covers every file read, so a spec kept as a folder of files shows drift
  when any part changes. Swagger 2.0 documents must be self-contained.
* OAuth2 token acquisition is not automatic (pass the token as the credential password).
* Cookie parameters, callbacks and webhooks are ignored; `oneOf`/`anyOf` of several object types become `[object]`.
* Swagger 2.0 support is best-effort; 3.0.x and 3.1 are the supported scope. YAML needs `ConvertFrom-Yaml`
  (`powershell-yaml`); anchors, aliases and merge keys work as far as that module supports them.
* A spec with no top-level `servers` uses the first server found on a path item or operation (paths sorted).

## Tests

`Test/OpenApiGeneration/` (Pester): parser, naming and name collisions, split specs and YAML, manifest editing,
generation/determinism/portability, behaviour with a mocked `Invoke-WebRequest` (Kokoro, Frigate, Open Food Facts, Open-Meteo,
password fields), the drift check for every committed client, and live Kokoro tests that skip themselves when the server
(`http://192.168.1.103:8880`, or `$env:KOKORO_ENDPOINT`) is unreachable. The YAML-based tests skip themselves when
`powershell-yaml` is not installed; CI installs it through the bootstrap script.
