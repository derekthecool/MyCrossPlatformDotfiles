# Dereks Cross-Platform Configuration Files

I primarily live in the terminal for everything. Coding, journaling, email, web
browsing... the list goes on.
**To be comfortable on your computer you need to cherish your dot file
configuration 💖!**

## Quick Installation Guide

Prerequisites before installing:

- `` git
- `` Powershell 7 or higher

```powershell
# Download the script
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/derekthecool/MyCrossPlatformDotfiles/master/Scripts/Dots/DotfileManagement.ps1' -OutFile ~/dot.ps1

# Dot source the script
. ~/dot.ps1

# Run the function to setup dotfiles
Initialize-Dotfiles && rm ~/dot.ps1
```

## Cross Platform Support

This configuration contains everything for my windows and Linux dot files.
While many of the programs are specific to either windows or Linux the
management and configuration setup of this repo is cross platform.

I'm using pwsh - the cross platform powershell for all of the repo management
scripts. Fresh installs, bare repo commit helpers, etc.

### Why Powershell?

Powershell is often seen as a Windows only tool.

My experience with it started with just trying to use the terminal for
everything. Using a Windows computer for work I've had to choose between legacy
CMD, powershell. There is WSL, and that can be great for getting a virtual Linux
setup it is still a bit sandboxed. So powershell was the clear choice.

Powershell is [FOSS](https://github.com/PowerShell/PowerShell?tab=MIT-1-ov-file#readme)
using the MIT license.

While I adore bash, zsh, fish, and other Linux only shells powershell is a clear
choice for a cross platform setup. Starting with powershell version 6 it is
cross platform. At the time of creating this configuration I'm using powershell
version 7.4.2.

Also Powershell is amazing because it uses an object pipeline and not just a
text pipeline. This provides so much power and makes basic tasks easier.

### Powershell Module [Dots](./Scripts/Dots/Dots.psd1]

[![Run Pester Tests on Linux](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-dotfiles-Linux.yaml/badge.svg)](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-dotfiles-Linux.yaml)
[![Run Pester Tests Windows](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-dotfiles-Windows.yaml/badge.svg)](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-dotfiles-Windows.yaml)
[![MegaLinter](https://github.com/derekthecool/MyCrossPlatformDotfiles/workflows/MegaLinter/badge.svg?branch=main)](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions?query=workflow%3AMegaLinter+branch%3Amain)

This repo comes with a powershell module included. This module is loaded with
functions to help with managing this repo as a git bare repo.
Many more functions are included as well.

For a fresh install run the script to get dependency modules installed

```powershell
./Scripts/Bootstrap-RequiredModules.ps1
```

Now the module can be loaded in two different ways.

1. Explicit load with `Import-Module -Force Dots`. After running this every
   function from the module will be availble for use.
2. Calling any of the **lazy loaded** functions from [Dots.psd1](./Scripts/Dots/Dots.psd1)
   As of July 2024, this list is pretty short containing only these functions:

   - `dot`: function for running any git commands but for the bare repo setup
     that I use for this repository.
   - `dots`: similar to dot but runs on all of my most important other missio
     critical repositories including:
   - `Initialize-Dotfiles`: clone any missing repos of mine such as
     [my-wezterm-repo][my-wezterm-repo], or [my-neovim-repo][my-neovim-repo]

## A Note About Shell Profile Precedence

### **PowerShell**

| Profile File                                                        | Used In This Repo | Repository File                                   |
| ------------------------------------------------------------------- | ----------------- | ------------------------------------------------- |
| **Machine-Wide, All Hosts**: `$profile.AllUsersAllHosts`            | no                |                                                   |
| **Machine-Wide, Host-Specific**: `$profile.AllUsersCurrentHost`     | no                |                                                   |
| **User-Specific, All Hosts**: `$profile.CurrentUserAllHosts`        | yes               | [profile.ps1](./Documents/PowerShell/profile.ps1) |
| **User-Specific, Host-Specific**: `$profile.CurrentUserCurrentHost` | no                |                                                   |

My preference is to avoid system-wide profiles because:

1. They require root/admin access to write
2. I'm the only one using my computer

And preferring CurrentUserAllHosts profile allows me to have a profile that can
apply to all of my various computers.
At work I use Windows 11, at home I use Arch Linux.
If necessary I can have any machine specific config in the
CurrentUserCurrentHost profile.

### **Bash**

- **Login Shells**:
  1. `/etc/profile`
  2. `~/.bash_profile`
  3. `~/.bash_login`
  4. `~/.profile`
- **Interactive Non-Login Shells**:
  1. `/etc/bash.bashrc`
  2. `~/.bashrc`

### **Zsh**

1. **Always Loaded**: `/etc/zshenv` → `~/.zshenv`
2. **Login Shells**: `/etc/zprofile` → `~/.zprofile`
3. **Interactive Shells**: `/etc/zshrc` → `~/.zshrc`
4. **Logout**: `/etc/zlogout` → `~/.zlogout`

## Included Programs

### Window Managers

#### [awesomewm](https://awesomewm.org/)

[![Test my awesome window manager lua configuration](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-awesomewm.yaml/badge.svg)](https://github.com/derekthecool/MyCrossPlatformDotfiles/actions/workflows/test-awesomewm.yaml)

AwesomeWM is a dynamic widow manager for Linux systems.
Files located `./.config/awesome/` and the config root file is
`./.config/awesome/rc.lua`.

### General Purpose Tools

| Application            | Configured With | My Config                                                  | Emoji Rating | Description                                                    |
| ---------------------- | --------------- | ---------------------------------------------------------- | ------------ | -------------------------------------------------------------- |
| [asciinema][asciinema] | conf            | [./.config/asciinema/config](./.config/asciinema/config)   |             | Awesome tool to record and play back terminal sessions         |
| [neomutt][neomutt]     | conf            | [./.config/neomutt/neomuttrc](.config/neomutt/neomuttrc)   |              | Terminal email clinet                                          |
| [vifm][vifm]           | vimscript like  | [./.config/vifm/vifmrc](./.config/vifm/vifmrc)             |              | Terminal file manager with vim like mappings                   |
| [starship][starship]   | toml            | [./.config/starship.toml](./.config/starship.toml)         | 󰱫            | Beautiful and functional terminal prompt. Highly configurable. |
| [zathura][zathura]     | vimscript like  | [./.config/zathura/zathurarc](./.config/zathura/zathurarc) |              | Vim-like PDF viewer (NOTE this is a graphical application)     |
| [rofi][rofi]           |                 | [./.config/rofi/config.rasi](./.config/rofi/config.rasi)   |              | Linux application launcher                                     |

## Separate Repositories Referenced

- My [Neovim](Neovim) configuration: [Stimpack][my-neovim-repo]
- My [Wezterm](Wezterm) configuration: [WeztermStimpack][my-wezterm-repo]
- My [Plover][Plover] configuration: [PloverStenoDictionaries][my-plover-repo]

[my-neovim-repo]: https://github.com/derekthecool/stimpack
[my-wezterm-repo]: https://github.com/derekthecool/WeztermStimpack
[Plover]: https://www.openstenoproject.org/plover/
[my-plover-repo]: https://github.com/derekthecool/PloverStenoDictionaries
[asciinema]: https://asciinema.org/
[neomutt]: https://neomutt.org/
[vifm]: https://vifm.info/
[starship]: https://starship.rs/
[zathura]: https://pwmt.org/projects/zathura/
[rofi]: https://davatorium.github.io/rofi/
