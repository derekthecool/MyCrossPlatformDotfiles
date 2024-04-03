# Dereks Cross-Platform Configuration Files

I primarily live in the terminal for everything. Coding, journaling, email, web browsing... the list goes on.
**To be comfortable on your computer you need to cherish your dot file configuration 💖!**

## Cross Platform Support

This configuration contains everything for my windows and Linux dot files.
While many of the programs are specific to either windows or Linux the
management and configuration setup of this repo is cross platform.

I'm using pwsh - the cross platform powershell for all of the repo management
scripts. Fresh installs, bare repo commit helpers, etc.

## Powershell

### Why Powershell?

Powershell is often seen as a Windows only tool. It is favored among IT
professionals.

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

### Powershell Modules

In order to keep the profile loading time as short as possible this
configuration uses powershell modules. Modules by default are lazy loaded.
Getting a profile to lazy load is nearly impossible, so moving functions out of
the profile is best.

### Powershell Profile

You can find where your profile is from the built in variable `$Profile`.
It is important to not load more than necessary in your powershell profile.
Only important items such as [PSReadLine](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.4)
and [Starship prompt](https://starship.rs/) should stay in the
actual profile.

## Quick Installation Guide

TODO: this is not working last time I tried it... 😦

```sh
curl -Lks https://github.com/derekthecool/MyLinuxConfigs/blob/master/.derek-shell-config/scripts/dotfilesetup.sh | /bin/bash
```

See the [dotfilesetup.sh script](~/.derek-shell-config/scripts/dotfilesetup.sh)
for the full details on how to install.

## Included Programs

### Text Editors

- tmux
- Vieb
- Alacritty
- asciinema
- awesome WM
- neomutt
- vifm
- zathura
- starship prompt

## Separate Projects Referenced

- Neovim config [Stim Pack](https://github.com/derekthecool/stimpack)
