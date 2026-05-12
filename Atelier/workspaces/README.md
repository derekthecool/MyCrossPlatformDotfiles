# Unified Window Manager Configuration

This system provides a unified way to manage window routing and filtering across Whim (Windows) and AwesomeWM (Linux) through JSON-based configuration files.

## Quick Start

```powershell
# View current configuration
Get-WM -Workspace 1,2,3
Get-WM -Filters

# Add new routes
'code', 'subl' | Add-WMRoute -Workspace 1

# Add new filters (non-tiled windows)
'blender', 'gimp' | Add-WMFilter

# Add with explicit type
@{Name='Alacritty'; Type='class'} | Add-WMRoute -Workspace 1
```

## Configuration Files

- **Location**: `~/Atelier/workspaces/`
- **Files**:
  - `1.json` through `9.json` - Window routing for each workspace
  - `filters.json` - Windows that should not be tiled (floating)

### JSON Schema

Each file contains an array of route objects:

```json
[
  { "app": "firefox", "type": "class" },
  { "app": "Alacritty", "type": "class" },
  { "app": ".*Plover: Lookup.*", "type": "title" }
]
```

**Identifier Types:**
- `process` - Process name (no `.exe` suffix, Whim adds it automatically)
- `class` - Window class name
- `title` - Window title (supports regex)
- `instance` - Instance name (AwesomeWM only)
- `role` - Window role (AwesomeWM only)

## PowerShell Module: DotWindowManager

**Location**: `~/Atelier/pwsh/MyModules/DotWindowManager/`

### Functions

- `Get-WM` - Retrieve window manager configuration
- `Add-WMRoute` - Add routes to workspaces
- `Add-WMFilter` - Add filters for non-tiled windows

### Pipeline Input Support

```powershell
# String input
'firefox', 'brave' | Add-WMRoute -Workspace 2

# Hashtable input
@{Name='Obsidian'; Type='class'} | Add-WMRoute -Workspace 5

# PSCustomObject input
[PSCustomObject]@{Name='.*Teams.*'; Type='title'} | Add-WMFilter
```

## Window Manager Integration

### Whim (Windows)

**Configuration**: `~/.whim/whim.config.csx`

The JSON routes are loaded automatically via:
```csharp
#load ".whim/json_routes.csx"
```

This file:
- Reads all workspace JSON files (1-9.json)
- Reads filters.json
- Maps JSON types to Whim's routing system
- Adds `.exe` suffix to process names automatically

### AwesomeWM (Linux)

**Configuration**: `~/.config/awesome/rc.lua`

The JSON routes are loaded automatically via:
```lua
local json_routes = require("json_routes")

-- Routes are added to awful.rules.rules
for _, rule in ipairs(json_routes.load_routes()) do
    table.insert(awful.rules.rules, rule)
end

-- Filters are added to awful.rules.rules
local filters = json_routes.load_filters()
-- ... filters added ...
```

**Dependencies**: `~/.config/awesome/json.lua` (rxi/json.lua library)

## Testing

```powershell
# Run Pester tests
Invoke-Pester ~/Atelier/pwsh/MyModules/DotWindowManager/Test/

# All 25 tests should pass
```

## Workflow

1. **Add routes/filters** using PowerShell:
   ```powershell
   'new-app' | Add-WMRoute -Workspace 2
   'floating-app' | Add-WMFilter
   ```

2. **JSON files are automatically updated** in `~/Atelier/workspaces/`

3. **Restart your window manager** to pick up changes:
   - Whim: Restart Whim
   - AwesomeWM: Reload config (Mod4 + Ctrl + r)

## Cross-Platform

- No `.exe` suffixes in JSON (Whim adds them automatically)
- Same JSON files work on both platforms
- Platform-specific identifiers (role, instance) only used where supported

## Migration Notes

All existing routes from both Whim and AwesomeWM have been migrated to the JSON files. The hardcoded routes in the WM configs can now be removed if desired, though keeping them as fallback doesn't hurt.
