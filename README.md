# Derek's Cross-Platform Configuration Files

[![Test MyCrossPlatformDotfiles Powershell Modules](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/Test_MyCrossPlatformDotfiles_Powershell_Modules.yaml/badge.svg)](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/Test_MyCrossPlatformDotfiles_Powershell_Modules.yaml)
[![MegaLinter](https://github.com/derekthecool/MyCrossPlatformDotfiles/workflows/MegaLinter/badge.svg?branch=master)](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions?query=workflow%3AMegaLinter+branch%3Amaster)

I primarily live in the terminal for everything. Coding, journaling, email, web
browsing... the list goes on.
**To be comfortable on your computer you need to cherish your dot file
configuration 💖!**

## What This Repository Is

This is a cross-platform dotfiles repository that manages my development environment
across **Linux (Arch)**, **macOS**, and **Windows 11**. It uses a unique **bare repository**
approach that allows me to live directly in my dotfiles while maintaining git history.

**Key features:**

- 🌍 Cross-platform PowerShell 7+ based management
- 📁 Bare git repository for seamless dotfile management
- ✅ Automated testing via GitHub Actions on all platforms
- 🖥️ Comprehensive window manager configurations (AwesomeWM, Whim, Workspacer)
- 🔄 Dual cloning workflow for daily usage and development

---

## Key Concepts

### Bare Repository Setup

This repository uses a **bare git repository** pattern:

- **Bare repo location**: `~/.cfg` (contains git data, no working tree)
- **Work tree location**: `$HOME` (your actual home directory)
- **Benefit**: Edit dotfiles directly in your home directory while maintaining git history

**In practice:**

- Edit `~/.config/awesome/rc.lua` → Changes are automatically tracked
- Use `dot status` to see changes (PowerShell) or `git --git-dir=$HOME/.cfg --work-tree=$HOME status` (bash)
- Commit with `dot commit` or the equivalent git command

### Dual Cloning Workflow

This repository is used in two ways:

1. **Bare Repository** (`~/.cfg`): For daily usage
   - Work tree at `$HOME`, git dir at `~/.cfg`
   - Edit configs directly in home directory
   - Use `dot` function (PowerShell) or `git --git-dir=$HOME/.cfg --work-tree=$HOME` (bash)

2. **Normal Repository** (e.g., `~/MyCrossPlatformDotfiles`): For development
   - Full `.git` directory for normal git operations
   - Use for testing, history, contributing
   - Standard `git` commands

---

## Quick Installation Guide

**Prerequisites:**

- `git`
- `PowerShell 7+` (pwsh)

**Installation steps:**

1. **Download the bootstrap script** - Loads the `dot` function and initialization tools
2. **Initialize dotfiles** - Clones the bare repository to `~/.cfg`
3. **Get additional configurations** - Clones related repos (Neovim, WezTerm, etc.)
4. **Install packages** - Installs platform-specific packages

```powershell
# Step 1: Download bootstrap script (long version)
Invoke-RestMethod 'https://raw.githubusercontent.com/derekthecool/MyCrossPlatformDotfiles/refs/heads/master/Atelier/pwsh/MyModules/Dot/Source/Dot.Functions.ps1' | Invoke-Expression

# Step 1: Download bootstrap script (short version)
irm 'https://rb.gy/49hpz2' | iex

# Step 2: Initialize bare repository
Initialize-Dotfiles

# Step 3: Clone other config repos
Get-AllConfigurations

# Step 4: Restart shell, then install packages
pwsh
Install-DotPackages
```

---

## Platform Support

This repository is tested and supported on:

- **Linux**: Arch Linux (primary), Ubuntu (via CI)
- **Windows**: Windows 11 (primary), Windows 10 (via CI)
- **macOS**: Latest versions (via CI)

**Platform-specific tools:**

- **Linux only**: AwesomeWM, rofi, picom, systemd integration
- **Windows only**: Whim, Workspacer, Microsoft Windows Terminal, Scoop package manager
- **Cross-platform**: PowerShell, Starship, Neovim, WezTerm, Alacritty, btop, yazi

[![Test my awesome window manager lua configuration](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-awesomewm.yaml/badge.svg)](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-awesomewm.yaml)

---

## Why PowerShell?

PowerShell is often seen as a Windows-only tool, but it's actually an excellent choice for cross-platform development.

**Why PowerShell for dotfiles management?**

- **Cross-platform**: PowerShell 7+ runs on Linux, macOS, and Windows
- **Object pipeline**: Uses objects instead of just text, making data manipulation easier
- **Consistent syntax**: Same language and cmdlets across all platforms
- **Powerful automation**: Advanced scripting capabilities with error handling
- **FOSS**: Open source with MIT license

**Alternative shells?**
While I adore bash, zsh, and fish, PowerShell is the clear choice for a unified cross-platform setup. Starting with PowerShell 6, it became truly cross-platform, and version 7.4+ provides excellent stability and features.

---

## Repository Structure

```
MyCrossPlatformDotfiles/
├── .config/                    # Application configurations
│   ├── awesome/               # AwesomeWM window manager (Linux)
│   ├── alacritty/             # Terminal emulator config
│   ├── asciinema/             # Terminal session recorder
│   ├── btop/                  # System monitor
│   ├── fish/                  # Fish shell configuration
│   ├── lftp/                  # FTP client
│   ├── neomutt/               # Email client
│   ├── picom/                 # Compositor (Linux)
│   ├── powershell/            # PowerShell module configs
│   ├── rofi/                  # Application launcher (Linux)
│   ├── starship.toml          # Cross-shell prompt
│   ├── vifm/                  # Terminal file manager
│   ├── yazi/                  # Modern terminal file manager
│   └── zathura/               # PDF viewer
├── Atelier/                    # Development workspace
│   └── pwsh/MyModules/        # Custom PowerShell modules
│       ├── Dot/               # Bare repo git operations
│       ├── Dots/              # Multi-repo operations
│       └── DotInitializer/    # Package installation
├── Documents/PowerShell/       # PowerShell profile
├── .github/workflows/          # CI/CD pipelines
├── AppData/                    # Windows-specific configs
│   ├── Local/                 # Windows local app data
│   └── Roaming/               # Windows roaming app data
├── scoop/                      # Windows package manager configs
├── .whim/                      # Whim window manager (Windows)
├── .workspacer/                # Workspacer window manager (Windows)
├── .bashrc                     # Bash shell configuration
├── .zshrc                      # Zsh shell configuration
├── .tmux.conf                  # Tmux configuration
├── .gitconfig                  # Global git configuration
└── .wslconfig                  # WSL configuration
```

---

## Core PowerShell Modules

This repository includes several custom PowerShell modules in `Atelier/pwsh/MyModules/`:

### **`dot`** - Bare Repository Git Operations

Git wrapper for bare repository operations.

**Usage:**

```powershell
dot status              # Check git status
dot add .config/        # Stage files
dot commit -m "message" # Commit changes
dot push                # Push to remote
```

**Bash equivalent:**

```bash
git --git-dir=$HOME/.cfg --work-tree=$HOME status
```

### **`dots`** - Multi-Repo Operations

Manages multiple configuration repositories simultaneously.

Operates on this repo plus related configs:

- This repository (dotfiles)
- [Stimpack](https://github.com/derekthecool/stimpack) (Neovim)
- [WeztermStimpack](https://github.com/derekthecool/WeztermStimpack) (WezTerm)
- [PloverStenoDictionaries](https://github.com/derekthecool/PloverStenoDictionaries) (Plover)

### **`Initialize-Dotfiles`** - Bootstrap Setup

Initializes the entire dotfiles setup.

**What it does:**

- Clones the bare repository to `~/.cfg`
- Sets up work tree at `$HOME`
- Configures git settings for bare repo
- Installs required PowerShell modules
- Creates backup of existing configs

### **`Install-DotPackages`** - Package Installation

Installs platform-specific packages and tools.

**Features:**

- Detects platform automatically (`$IsWindows`, `$IsLinux`, `$IsMacOS`)
- Uses appropriate package manager:
  - **Windows**: Scoop (primary), WinGet
  - **macOS**: Homebrew
  - **Linux**: pacman (Arch), apt (Ubuntu), detects available
- Installs essential development tools, terminal applications, and utilities

---

## Program Configurations

### Window Managers

#### **AwesomeWM** (Linux)

- **Location**: `.config/awesome/`
- **Root file**: `.config/awesome/rc.lua`
- **Features**: Multi-monitor support, dynamic tagging, auto-start, client routing
- **Tested**: ✅ Syntax-checked via CI

#### **Whim** (Windows)

- **Location**: `.whim/`
- **Files**: `whim.config.csx`, `whim.config.yaml`
- **Features**: Modern tiling window manager for Windows 11

#### **Workspacer** (Windows)

- **Location**: `.workspacer/`
- **File**: `workspacer.config.csx`
- **Features**: Tiling window manager for Windows 10/11

### Terminal Applications

#### **Starship** (Cross-Platform)

- **Location**: `.config/starship.toml`
- **Description**: Beautiful, fast, customizable prompt for any shell
- **Features**: Multi-shell support, git integration, AWS context, etc.

#### **Alacritty** (Cross-Platform)

- **Location**: `.config/alacritty/`
- **Description**: Fast, GPU-accelerated terminal emulator
- **Features**: Custom color schemes, key bindings, fonts

#### **WezTerm** (Cross-Platform)

- **Location**: Separate repository - [WeztermStimpack](https://github.com/derekthecool/WeztermStimpack)
- **Description**: GPU-accelerated terminal emulator with multiplexing

#### **Windows Terminal** (Windows)

- **Location**: `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/`
- **Description**: Modern terminal application for Windows 11

### Shells

#### **PowerShell** (Cross-Platform)

- **Profile**: `Documents/PowerShell/profile.ps1`
- **Features**: Custom aliases, PSReadLine configuration, modules, cross-platform paths

#### **Bash** (Cross-Platform)

- **Config**: `.bashrc`
- **Features**: Starship prompt, fzf integration, WSL detection

#### **Zsh** (Cross-Platform)

- **Config**: `.zshrc`
- **Features**: Oh-My-Zsh, custom plugins, Starship prompt

#### **Fish** (Cross-Platform)

- **Location**: `.config/fish/`
- **Features**: Starship integration, abbreviations

### Terminal Tools

#### **Neovim** (Cross-Platform)

- **Location**: Separate repository - [Stimpack](https://github.com/derekthecool/stimpack)
- **Description**: Modern, extensible text editor
- **Features**: Lua configuration, LSP, fuzzy finder, git integration

#### **Vifm** (Cross-Platform)

- **Location**: `.config/vifm/vifmrc`
- **Description**: Vim-like file manager
- **Features**: Vim keybindings, custom colors, file operations

#### **Yazi** (Cross-Platform)

- **Location**: `.config/yazi/`
- **Description**: Modern terminal file manager written in Rust
- **Features**: Fast, visually appealing, plugin system

#### **btop** (Cross-Platform)

- **Location**: `.config/btop/`
- **Description**: Beautiful, resource-efficient system monitor
- **Features**: CPU, GPU, RAM, disk, network monitoring

#### **Tmux** (Cross-Platform)

- **Config**: `.tmux.conf`
- **Description**: Terminal multiplexer
- **Features**: Custom key bindings, status bar, pane management

### File Transfer & Communication

#### **Neomutt** (Cross-Platform)

- **Location**: `.config/neomutt/neomuttrc`
- **Description**: Terminal email client
- **Features**: Vim keybindings, notmuch integration, GPG

#### **lftp** (Cross-Platform)

- **Location**: `.config/lftp/`
- **Description**: Sophisticated FTP/HTTP client
- **Features**: Bookmark support, mirror, queue management

#### **yt-dlp** (Cross-Platform)

- **Config**: `yt-dlp.conf`
- **Description**: Video downloader for YouTube and other sites
- **Features**: Format selection, subtitles, archive handling

### PDF & Documents

#### **Zathura** (Cross-Platform)

- **Location**: `.config/zathura/zathurarc`
- **Description**: Vim-like PDF viewer
- **Features**: Vim keybindings, minimal UI, fast rendering

#### **Pandoc** (Cross-Platform)

- **Location**: `.pandoc/`
- **Description**: Universal document converter
- **Features**: Custom templates, defaults

### Linux-Specific Tools

#### **Rofi** (Linux)

- **Location**: `.config/rofi/config.rasi`
- **Description**: Application launcher and window switcher
- **Features**: Custom themes, key bindings, drun mode

#### **Picom** (Linux)

- **Location**: `.config/picom/`
- **Description**: Compositor for X11
- **Features**: Blur effects, transparency, vsync

### Windows-Specific Tools

#### **Vieb** (Windows)

- **Location**: `AppData/Roaming/Vieb/`
- **Description**: Vim-like browser
- **Features**: Vim keybindings for web browsing

#### **Termscp** (Windows)

- **Location**: `AppData/Roaming/termscp/`
- **Description**: Terminal file transfer with SCP/SFTP
- **Features**: Graphical file transfer over SSH

### Development Tools

#### **Git** (Cross-Platform)

- **Config**: `.gitconfig`
- **Features**: IncludeIf directives, URL shortcuts, credential helpers

#### **Clang-Format** (Cross-Platform)

- **Config**: `.clang-format`
- **Description**: Code formatter for C/C++/Java/JavaScript
- **Features**: Consistent code style

#### **WSL** (Windows)

- **Config**: `.wslconfig`
- **Description**: Windows Subsystem for Linux configuration
- **Features**: Memory settings, networking, interop

### Linting & Quality

#### **Mega-Linter** (Cross-Platform)

- **Config**: `.mega-linter.yml`
- **Description**: Meta-linter running 70+ linters
- **Features**: Markdown, shell scripts, JSON, YAML, spelling

#### **CSpell** (Cross-Platform)

- **Config**: `.cspell.json`
- **Description**: Code spell checker
- **Features**: Custom dictionary, ignore patterns

#### **JSCPD** (Cross-Platform)

- **Config**: `.jscpd.json`
- **Description**: Copy/paste detector
- **Features**: Find duplicate code

#### **GitLeaks** (Cross-Platform)

- **Config**: `.gitleaksignore`
- **Description**: Secret scanner
- **Features**: Prevent committing sensitive data

---

## Shell Profile Precedence

### **PowerShell**

| Profile File                                                        | Used In This Repo | Repository File                                   |
|---------------------------------------------------------------------|-------------------|---------------------------------------------------|
| **Machine-Wide, All Hosts**: `$profile.AllUsersAllHosts`            | no                |                                                   |
| **Machine-Wide, Host-Specific**: `$profile.AllUsersCurrentHost`     | no                |                                                   |
| **User-Specific, All Hosts**: `$profile.CurrentUserAllHosts`        | yes               | [profile.ps1](./Documents/PowerShell/profile.ps1) |
| **User-Specific, Host-Specific**: `$profile.CurrentUserCurrentHost` | no                |                                                   |

**Why `CurrentUserAllHosts`?**

- Avoids requiring root/admin access
- Applies to all my computers (Windows 11 at work, Arch Linux at home)
- Machine-specific config can go in `CurrentUserCurrentHost` if needed

### **Bash**

- **Login Shells**: `/etc/profile` → `~/.bash_profile` → `~/.bash_login` → `~/.profile`
- **Interactive Non-Login Shells**: `/etc/bash.bashrc` → `~/.bashrc`

### **Zsh**

1. **Always Loaded**: `/etc/zshenv` → `~/.zshenv`
2. **Login Shells**: `/etc/zprofile` → `~/.zprofile`
3. **Interactive Shells**: `/etc/zshrc` → `~/.zshrc`
4. **Logout**: `/etc/zlogout` → `~/.zlogout`

---

## Development & Testing

### Running Tests

**PowerShell modules:**

```powershell
# Run all PowerShell module tests
./DotfilesTests.ps1

# Run specific module tests
Invoke-Pester -Path Atelier/pwsh/MyModules/Dot/Test/
```

**AwesomeWM configuration:**

```bash
# Test AwesomeWM syntax
awesome --check ./.config/awesome/rc.lua
```

### CI/CD Pipeline

All changes are tested via GitHub Actions:

- **PowerShell module tests**: Pester framework on Linux, macOS, Windows
- **AwesomeWM syntax check**: Lua validation on Ubuntu
- **Mega-Linter**: Code quality checks on all files
- **Package installation**: Tests `Install-DotPackages` on all platforms

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Ensure tests pass on all platforms
5. Submit a pull request

**Guidelines:**

- Follow conventional commit format: `docs(claude): redesign README`
- Test on all three platforms if possible
- Add tests for new features
- Update documentation as needed

---

## Troubleshooting

### **"dot: command not found"**

The `dot` function is PowerShell-only. Use the equivalent in bash:

```bash
git --git-dir=$HOME/.cfg --work-tree=$HOME <command>
```

### **"Bare repo already exists"**

Remove the existing bare repository and re-initialize:

```bash
rm -rf ~/.cfg
Initialize-Dotfiles
```

### **"PowerShell 7 not found"**

Install PowerShell 7+:

- **Windows**: `scoop install pwsh` or `winget install Microsoft.PowerShell`
- **macOS**: `brew install powershell`
- **Arch Linux**: `pacman -S powershell`
- **Ubuntu**: `snap install powershell --classic`

### **Tests failing on one platform**

- Check platform-specific logic (`$IsWindows`, `$IsLinux`, `$IsMacOS`)
- Verify path separators (`[System.IO.Path]::PathSeparator`)
- Check environment variables (`$HOME`, `$env:LOCALAPPDATA`)
- Test on all three platforms via GitHub Actions

### **Changes not being tracked**

Ensure you're in the correct git context:

- **Bare repo**: Use `dot status` or check `~/.cfg` exists
- **Normal repo**: Use `git status` and ensure `.git` directory exists

### **Windows Terminal not finding configs**

Windows Terminal stores configs in a package directory. The config location is:
`AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`

---

## Separate Repositories

Some configurations are maintained in separate repositories for better organization:

- **[Neovim](https://neovim.io/)**: [Stimpack](https://github.com/derekthecool/stimpack)
- **[WezTerm](https://wezterm.org/)**: [WeztermStimpack](https://github.com/derekthecool/WeztermStimpack)
- **[Plover](https://www.openstenoproject.org/plover/)**: [PloverStenoDictionaries](https://github.com/derekthecool/PloverStenoDictionaries)

These are automatically cloned by `Get-AllConfigurations` during installation.

