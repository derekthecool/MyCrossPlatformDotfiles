# Personal settings
# PowerShell 7 (pwsh)

# Set Starship prompt
# Config file is located: ~/.config/starship.toml
# Support for OSC7 (CWD detector or wezterm terminal emulator)
$prompt = ''
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq 'FileSystem') {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace '\\', '/'
        $env:r = [IO.Path]::GetPathRoot($provider_path)

        # OSC 7
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}
Invoke-Expression (&starship init powershell)

# Configure PSReadLine. Does not like to be loaded from another script with dot sourcing.
Set-PSReadLineOption -EditMode vi
Set-PSReadLineOption -ViModeIndicator Prompt
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Set editor environment variables
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

# # Load these configuration items now (not lazy loaded)
. "$HOME/MyCrossPlatformScripts/Setup-LazyLoadFunctions.ps1"

# Call function function lazy load dot sourced scripts
# Initial setup cut my startup time from 1223ms to 700ms
Setup-LazyLoadFunctions -LazyLoadFunctions @{
    'dot' = "$HOME/MyCrossPlatformScripts/Invoke-DotGit.ps1"
    'Setup-DotnetTools' = "$HOME/MyCrossPlatformScripts/Setup-DotnetTools.ps1"

    # Windows only
    'Start-VSCompiler' = "$HOME/MyCrossPlatformScripts/Windows/Start-VSCompiler.ps1"
}


if($IsWindows) {
    $env:Path +=  ";$env:PROGRAMFILES\Open Steno Project\Plover 4.0.0.dev12\"
    $env:Path += ';C:\Windows\System32'
    $env:Path += ';C:\Program Files\Oracle\VirtualBox\'
}

# Better diff using git
# First overwrite the annoying built in alias to Compare-Object
Remove-Item alias:diff -Force
# Now set the alias
function diff {
    git diff --no-index --color-words $args
}

## Add all these tools downloaded from neovim plugin Mason
## https://github.com/williamboman/mason.nvim
$mason_bin_path = "$env:LOCALAPPDATA\nvim-data\mason\bin"
if(Test-Path $mason_bin_path) {
    $env:Path += ";$mason_bin_path"
}




# gh (GitHub CLI) completion
Invoke-Expression -Command $(gh completion -s powershell | Out-String)

# This function sets all the build environment for ESP-IDF
function Source-Espidf() {
    # Customize these for your install path and version
    $version = '5.0.1'
    $root_location = 'D:\'

    # Set environment variable
    $env:IDF_PATH = "${root_location}Espressif\frameworks\esp-idf-v${version}"

    # Run the setup script
    Invoke-Expression "${root_location}Espressif/Initialize-Idf.ps1"
}

function Get-TopProcesses {
    Get-Process | Group-Object -Property ProcessName |
        ForEach-Object {
            [PSCustomObject]@{
                ProcessName = $_.Name
                Mem_MB = [math]::Round(($_.Group|Measure-Object WorkingSet64 -Sum).Sum / 1MB, 0)
                ProcessCount = $_.Count
            }
        } | Sort-Object -desc Mem_MB | Select-Object -First 25
}

# Function designed to basically be like dotnet watch
function Watch-FileChange {
    param(
        [string]$Path,
        [string]$Filter = '*',
        [scriptblock]$Action
    )

    Get-EventSubscriber | Unregister-Event

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Path
    $watcher.Filter = $Filter
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'

    # Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier FileCreated -Action $Action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier FileChanged -Action $Action
    # Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier FileDeleted -Action $Action
    # Register-ObjectEvent -InputObject $watcher -EventName Renamed -SourceIdentifier FileRenamed -Action $Action

    Write-Host "Monitoring changes to files in $Path with filter $Filter..."
    Write-Host 'Press CTRL+C to stop.'
}
