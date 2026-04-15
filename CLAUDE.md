# CLAUDE

## Core Principles

### 1. Always Plan First

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Write detailed specs upfront to reduce ambiguity

### 2. Test-Driven Development

- **Always** write tests alongside code
- **Always** create GitHub Actions that run tests automatically
- Never mark a task complete without proving it works
- Run tests, check logs, demonstrate correctness

### 3. PowerShell Over Bash

- Prefer PowerShell for all automation and scripting tasks
- PowerShell 7+ is cross-platform and more powerful than bash
- Use object pipeline, not just text pipeline
- Reserve bash only for simple POSIX-compliant sh scripts

### 4. Cross-Platform Awareness

- Never hard-code paths or platform-specific behavior
- Test on Linux, macOS, and Windows before considering work complete
- Use platform detection (`$IsWindows`, `$IsLinux`, `$IsMacOS`)
- Handle path separators properly (`[System.IO.Path]::PathSeparator`)

### 5. Conventional Commits

- **Always** use conventional commit format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, etc.
- Examples: `feat(awesome): add multi-monitor support`, `fix(pwsh): correct path handling`
- Keep descriptions concise and imperative mood

### 6. Clean Commit Messages

- **Never** include the Claude footer (`Co-Authored-By: Claude Sonnet...`) in commit details
- Commit messages should be clean and professional
- The footer is noise that doesn't add value to your git history

---

## This Repository: Cross-Platform Dotfiles

This is your home directory dotfiles repository managing Linux (Arch), macOS, and Windows 11 configurations.

### Dual Cloning Setup

This repository is cloned in two ways:

1. **Bare Repository** (`~/.cfg`): For living in your dotfiles
   - Work tree at `$HOME`, git dir at `~/.cfg`
   - Edit configs directly in home directory

2. **Normal Repository** (e.g., `~/MyCrossPlatformDotfiles`): For development
   - Full `.git` directory for normal git operations
   - Use for testing, history, contributing

### Git Context Awareness

**CRITICAL**: Always check which git context you're in before operations

- **In bare repo** (editing dotfiles in `$HOME`):
  - Bash/zsh: `git --git-dir=$HOME/.cfg --work-tree=$HOME <commands>`
  - PowerShell: `dot` function (PowerShell-only, won't work in bash)

- **In normal repo** (development):
  - Use normal `git` commands

**Reference**: `Atelier/pwsh/MyModules/Dot/Source/Dot.Functions.ps1`

### Cross-Platform Gotchas

- **Paths**: Use `Join-Path`, `$HOME` (not `~`), `[System.IO.Path]::PathSeparator`
- **Case sensitivity**: Linux is case-sensitive, Windows/macOS are not
- **Line endings**: `.gitattributes` enforces LF for `*.lua`, `*.toml`
- **Encoding**: UTF-8 enforced everywhere
- **Commands**: Check existence with `Get-Command -ErrorAction SilentlyContinue`
- **PowerShell version**: Require 7+, not PS 5.1

### Testing Requirements

- **PowerShell modules**: Pester tests in `Test/` subdirectories, run with `./DotfilesTests.ps1`
- **AwesomeWM configs**: `awesome --check ./.config/awesome/rc.lua`
- **Cross-platform CI**: GitHub Actions matrix (Ubuntu, macOS, Windows)
- **All changes**: Must pass tests on all platforms before merging

---

## Task Management

1. **Plan First**: Write plan for non-trivial tasks
2. **Track Progress**: Use task list to track work
3. **Test Everything**: Write tests and GitHub Actions
4. **Verify Before Done**: Prove it works end-to-end

---

## Common Pitfalls

### Don't Mix Git Contexts
- Using `dot` function in bash (PowerShell-only)
- Forgetting which repo context you're in
- Assuming bare repo exists (may be in CI/normal clone)

### Don't Ignore Platforms
- Hard-coding Windows paths on Linux
- Assuming Unix tools exist on Windows
- Forgetting case sensitivity on Linux

### Don't Skip Testing
- Writing code without tests
- Not creating GitHub Actions
- Assuming "it works" without verification

---

## Quick Reference

### Cross-Platform Path Handling
```powershell
# Right
Join-Path $HOME "Documents"
$env:PATH += [System.IO.Path]::PathSeparator + "/new/path"

# Wrong
"$HOME/Documents"
$env:PATH += ":/new/path"  # Only works on Unix
```

### Platform Detection
```powershell
if ($IsWindows) { $configPath = $env:LOCALAPPDATA }
elseif ($IsLinux -or $IsMacOS) { $configPath = "$HOME/.config" }
```

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

- `Atelier/pwsh/MyModules/Dot/Source/Dot.Functions.ps1` - Bare repo `dot` function
- `Documents/PowerShell/profile.ps1` - Cross-platform patterns
- `DotfilesTests.ps1` - Test runner
- `.github/workflows/` - Cross-platform CI
- `.gitattributes` - Line ending configuration