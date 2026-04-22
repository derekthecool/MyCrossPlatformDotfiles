# Whim Window Manager Configuration

## Overview

This directory contains the configuration for [Whim](https://github.com/jcpark/whim), a tiling window manager for Windows 11.

## Platform

**⚠️ Windows-Only:** Whim is a Windows-only window manager. There is no Linux or macOS equivalent.

## Configuration Files

- `whim.config.yaml` - Declarative configuration for layouts, keybinds, and plugins
- `whim.config.csx` - C# scripting configuration for advanced customization

## Path Conventions

### C# Script DLL References

When referencing DLLs in `whim.config.csx`, use environment variables or system-wide paths:

**✅ Good:**
```csharp
#r "C:\Program Files\Whim\whim.dll"
#r "C:\Program Files\Whim\plugins\Whim.Bar\Whim.Bar.dll"
```

**❌ Bad (Hardcoded Username):**
```csharp
#r "C:\Users\dlomax\scoop\apps\workspacer\current\workspacer.Shared.dll"
```

### Why This Matters

Hardcoded usernames break cross-platform setups because:
1. Each user has a different username
2. Configurations can't be shared across users
3. Breaks automated setup scripts

### Environment Variables to Use

- `$env:ProgramFiles` → `C:\Program Files\`
- `$env:LOCALAPPDATA` → `C:\Users\<username>\AppData\Local\`
- `$env:APPDATA` → `C:\Users\<username>\AppData\Roaming\`

## Testing

The GitHub Actions workflow `.github/workflows/test-whim.yaml` validates:
1. YAML syntax using `yamllint`
2. C# script patterns (checks for hardcoded usernames)
3. DLL reference conventions

## Related Configurations

- **Linux:** See `~/.config/awesome/` for AwesomeWM configuration
- **PowerShell:** See `~/Documents/PowerShell/` for cross-platform PowerShell setup