# Plan: Destroy the `Dots` Module

## Context

The `Dots` module at `Atelier/pwsh/MyModules/Dots/` is a grab-bag of functions plus several tab-completion registrations with no coherent theme. Its `.psm1` recursively dot-sources every `.ps1` under the folder and runs `Add-MasonToolsToPath` as a load-time side effect. Tests live in the legacy central `MyModules/Tests/` folder rather than per-module. No external code references the module by name; all function calls are internal.

Goal: delete the module entirely and redistribute its functions into focused modules that follow the standard `Source/` + `Test/` layout used by `DotCore`, `DotGit`, `DotImages`, etc. Some functions will be trashed; most will be migrated to five new modules (`DotSdk`, `DotSystem`, `DotSerial`, `DotDatabase`, `DotCompleter`) or absorbed into existing modules (`DotCore`, `DotImages`, `DotInitializer`, `DotPcap`).

Guiding rules from the user:
- `DotCore` must stay lean and load fast — only `Watch-FileChange`, `Convert-FileToHexString`, and `Get-BytesToSize` go there (each judged essential enough to justify inclusion).
- No catch-all completion module — orphan completers get trashed.
- Functions grouped by domain go into new focused modules.
- Side-effecting setup code (PATH mutation) stays in a module, not profile.

## Migration Map

### Trash (delete entirely)

| File | Reason |
|---|---|
| `Dots/Demos/Dots.demo.ps1` | Demo file, no real functions |
| `Expand-Number` (and alias `number`) | User considers low-value; trashing |
| `CustomSortOrder` (internal helper in `TabCompletion/Dotnet.ps1`) | Travels with dotnet completer — inline as private when migrated |

### New modules to create (5)

Each new module follows the standard layout: `<Name>.psd1`, `<Name>.psm1` (dot-sources `Source/*.ps1`), `Source/`, `Test/`. Use the `DotCore.psd1` / `DotCore.psm1` pattern as the template.

#### 1. `DotSdk` — dotnet SDK, VS compiler, gcc
- `Get-DotnetOutdatedPackage` (alias `dotnet-GetOutdated`) — from `Dots/Programming/dotnet.ps1`
- `Start-VSCompiler` — from `Dots/Windows/Start-VSCompiler.ps1` (keep the `if ($IsWindows)` guard around the function definition, or inside it)
- Dotnet native argument completer — from `Dots/TabCompletion/Dotnet.ps1`; inline `CustomSortOrder` as a private function inside the same file
- GCC argument completer — extract from `General-Completion.ps1`, reusing the `Get-GeneralCompletion` pattern (call `<cmd> --help`, parse with `ConvertFrom-Text`, register). Inline the helper locally or import `Get-GeneralCompletion` from `DotCompleter`.

#### 2. `DotSystem` — diagnostics, profiling, downloads
- `Get-Benchmark`, `Get-BenchmarkTotalMilliseconds` — from `Dots/Get-Benchmark.ps1` (keep `#requires -Modules Profiler`)
- `Get-CombinedCPUUsagePercentage`, `Get-TopMemoryProcesses` — from `Dots/RamAndCpuFunctions.ps1`
- `Get-ISO`, `Get-ISOFilename` — from `Dots/Download-Commands.ps1` (merged in from the now-folded DotDownload per user direction; broader scope than pure diagnostics)

#### 3. `DotSerial` — serial ports
- `Get-SerialPort` (alias `ports`) — from `Dots/General/SerialPortFunctions.ps1`. The existing TODO comment ("split this into another module") is fulfilled by this module.

#### 4. `DotDatabase` — database helpers
- `Invoke-Mysql` — from `Dots/Database/SimplySqlHelpers.ps1`. (Note: hardcoded default DB `OrionPineappleFota` stays as-is per user's "keep everything else" guidance — can be cleaned up later.)

#### 5. `DotCompleter` — orphan CLI completers
- `Get-GeneralCompletion` helper — from `Dots/TabCompletion/General-Completion.ps1`
- Native argument completer registrations for orphan CLI tools: `gh`, `winget`, `mosquitto_sub`, `mosquitto_pub`, `lftp`, `curl`, `grep`, `lua`. These are tools with no dedicated `Dot*` module of their own.

### Migrations to existing modules

| Function | Destination | New file |
|---|---|---|
| `ffmpeg-ReduceVideoSize` | `DotImages` | `Source/FFmpeg.ps1` |
| `Add-MasonToolsToPath` | `DotInitializer` | `Source/MasonPath.ps1` |
| `Watch-FileChange` | `DotCore` | `Source/WatchFileChange.ps1` |
| `Convert-FileToHexString` | `DotCore` | `Source/ConvertFileToHexString.ps1` |
| `Get-BytesToSize` | `DotCore` | `Source/GetBytesToSize.ps1` |
| tshark argument completer | `DotPcap` | `Source/TsharkCompletion.ps1` (extract from `General-Completion.ps1`, inline the `Get-GeneralCompletion` pattern) |

### Module manifest updates

For each new/modified module, update `FunctionsToExport` and `AliasesToExport` in its `.psd1` to list the migrated functions/aliases explicitly (matches the existing `DotCore.psd1` convention — no wildcards, keeps lazy-load fast). For `DotCore`, add `Convert-FileToHexString` and `Get-BytesToSize` to the existing `FunctionsToExport` list.

### Test migrations

The current `MyModules/Tests/` central folder holds three test files for Dots functions. Move them to per-module `Test/` folders to match the dominant convention:

| Current path | New path |
|---|---|
| `Tests/NeovimRelated/Add-MasonToolsToPath.Tests.ps1` | `DotInitializer/Test/Add-MasonToolsToPath.Tests.ps1` |
| `Tests/Benchmark/ProfilePerformance.Tests.ps1` | `DotSystem/Test/ProfilePerformance.Tests.ps1` |
| `Tests/Download-Commands.Tests.ps1` | `DotSystem/Test/Download-Commands.Tests.ps1` |

After moves, the legacy `Tests/` folder should be checked for remaining content; if empty, delete it.

### Final cleanup

Once all migrations are verified by tests:
1. Delete the entire `Dots/` directory.
2. Remove any stale reference in `DotfilesTests.ps1` if it special-cases `Dots`.
3. Confirm `MyModules/Tests/` is empty or gone.

## Order of Operations

1. Create the five new modules with manifests + `.psm1` (copy structure from `DotCore`).
2. Move functions into the new modules' `Source/` folders; update each manifest's `FunctionsToExport`/`AliasesToExport`.
3. Add migrated functions to existing modules (`DotImages`, `DotInitializer`, `DotCore`, `DotPcap`); update those manifests.
4. Move test files to their new per-module `Test/` locations.
5. Run `./DotfilesTests.ps1` and confirm everything passes.
6. Delete `Dots/` directory and the emptied `Tests/` folder.
7. Commit with conventional message: `refactor(pwsh): dismantle Dots module, distribute functions to focused modules`.

## Verification

- `./DotfilesTests.ps1` passes on Linux (current platform).
- `pwsh -c "Get-Module -ListAvailable Dot*"` shows the five new modules with correct version + exported functions.
- `pwsh -c "Import-Module DotSdk; Get-DotnetOutdatedPackage -?"` returns help (function is callable).
- `pwsh -c "Import-Module DotInitializer; Add-MasonToolsToPath"` runs without error.
- `pwsh -c "Import-Module DotCore; Get-BytesToSize -Bytes 12345"` returns a human-readable size.
- `pwsh -c "Import-Module DotCore; Convert-FileToHexString -FilePath /etc/hostname"` returns hex.
- `pwsh -c "Import-Module DotSystem; Get-ISOFilename -Filename 'http://example.com/foo.iso'"` returns `foo.iso`.
- `pwsh -c "Import-Module DotCompleter; Get-GeneralCompletion -Command 'curl'"` returns parsed help options.
- `pwsh -c "Import-Module DotSerial; Get-SerialPort"` either lists ports or throws the expected "pyserial not found" error.
- `number` / `Expand-Number` are no longer present in any module.
- CI matrix (Ubuntu/macOS/Windows) passes — call out in the PR description if any platform-specific function (e.g. `Start-VSCompiler`) cannot be tested locally on Linux.
- `grep -rn "Dots" Atelier/pwsh/` returns no leftover references.

## Open considerations

- **`Add-MasonToolsToPath` auto-run**: Today the `Dots.psm1` calls this at module load. After moving to `DotInitializer`, decide whether `DotInitializer.psm1` should also auto-invoke it on import, or whether the user invokes it explicitly. Recommend NOT auto-running on module import (auto-discovery is lazy), and instead invoking from `profile.ps1` if session-start behavior is desired. Flag this for the user during implementation.
- **`Invoke-Mysql` hardcoded DB name**: `OrionPineappleFota` is hardcoded as the default. Leaving as-is per user direction, but flag for future cleanup.
- **GCC/tshark helper reuse**: The `Get-GeneralCompletion` helper now lives in `DotCompleter`. Both `DotSdk` (gcc) and `DotPcap` (tshark) need it — they should `Import-Module DotCompleter` (or declare it in `RequiredModules`) rather than duplicate the pattern. Confirm dependency direction during implementation.
