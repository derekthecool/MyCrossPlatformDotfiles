# CLAUDE

## Core Principles

1. **Plan first** — enter plan mode for non-trivial tasks (3+ steps/architectural); re-plan if it goes sideways.
2. **Test-driven** — write tests alongside code, add CI to run them, prove it works before calling it done.
3. **PowerShell over Bash** — PS 7+ for automation; use the object pipeline. Bash only for simple POSIX sh.
4. **Cross-platform** — no hard-coded paths; detect with `$IsWindows`/`$IsLinux`/`$IsMacOS`; `Join-Path` + `[IO.Path]::PathSeparator`.
5. **Conventional commits** — `type(scope): description`, imperative. No Claude footer in messages.

## This Repository: Cross-Platform Dotfiles

Manages Linux (Arch), macOS, Windows 11 configs. Cloned two ways:
- **Bare** (`~/.cfg`, work-tree `$HOME`) — live editing. Bash: `git --git-dir=$HOME/.cfg --work-tree=$HOME …`; PS: `dot` function (PS-only).
- **Normal** (e.g. `~/MyCrossPlatformDotfiles`) — development; plain `git`.

**Always confirm which git context you're in first.** Gotchas: case-sensitive on Linux only; `.gitattributes` enforces LF for `*.lua`/`*.toml`; UTF-8 everywhere; require PS 7+ (not 5.1); check commands with `Get-Command -EA SilentlyContinue`.

**Testing**: Pester in `Test/` via `./DotfilesTests.ps1`; `awesome --check ./.config/awesome/rc.lua`; CI matrix on Ubuntu/macOS/Windows — must pass on all before merge.

## Quick Reference

```powershell
Join-Path $HOME "Documents"                      # not "$HOME/Documents"
$env:PATH += [IO.Path]::PathSeparator + "/new"   # not ":/new" (Unix-only)
if ($IsWindows) { $env:LOCALAPPDATA } else { "$HOME/.config" }
```

### Platform Detection
```powershell
if ($IsWindows) { $configPath = $env:LOCALAPPDATA }
elseif ($IsLinux -or $IsMacOS) { $configPath = "$HOME/.config" }
```

### PowerShell Function Aliases
Use `CmdletBinding()` with an empty `param()` block and `[Alias('name')]` attribute on functions. Never use `Set-Alias`.

### Git Operations
```bash
# Bare repo (editing dotfiles)
git --git-dir=$HOME/.cfg --work-tree=$HOME status

# Normal repo (development)
git status
```

```powershell
# Bare repo (PowerShell only)
dot status

# Normal repo
git status
```

---

## Critical Files

- `Atelier/pwsh/MyModules/Dot/Source/Dot.Functions.ps1` — bare-repo `dot` function
- `Documents/PowerShell/profile.ps1` — cross-platform patterns
- `DotfilesTests.ps1` — test runner; `.github/workflows/` — CI; `.gitattributes` — line endings

## PowerShell

### Concurrent TUIs

Lessons from a parallel runner with a live PwshSpectreConsole dashboard (`Start-ThreadJob` + `Invoke-SpectreLive`). Bugs are concurrency-dependent — test with several workers, not one.

1. **Never pass a scriptblock object across runspaces** — it's bound to its creating runspace; running it in a `Start-ThreadJob` corrupts scope ("Stack empty", built-ins "not recognized"). Pass `.ToString()`, rebuild with `[scriptblock]::Create($using:text)` in the worker.
2. **The Spectre live/status delegate runs in a bare runspace** (global + built-ins only): `Import-Module -Global`, `.GetNewClosure()`, define helpers inline, keep real work in worker jobs.
3. **Escape dynamic strings before markup** — unescaped `[...]` crashes ("Could not find color or style"). `Get-SpectreEscapedText` or `-replace '\[','[[' -replace '\]',']]'`.
4. **Gate live UI on a real TTY** — `[Console]::IsOutputRedirected` (WindowWidth lies as 80 when piped); always offer a `-Plain` streaming fallback.
5. **StrictMode/concurrency** — `@()` before `.Count`; `return , $list` to avoid unrolling; no `if` in argument position; `Write-SpectreRule | Out-Host` inside value-returning functions.
