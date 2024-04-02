# Personal settings
# PowerShell 7 (pwsh)

# Function to using my git bare repo for my windows config files
function dot {
    git --git-dir="$env:USERPROFILE\.cfg" --work-tree="$env:USERPROFILE" $args
}

# Stop dotnet telemetry
$env:DOTNET_CLI_TELEMETRY_OPTOUT = $true
# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Set PSReadLine Awesome Features
# Set vi mode
Set-PSReadLineOption -EditMode vi
Set-PSReadLineOption -ViModeIndicator Prompt
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Setting the environment variables EDITOR, and VISUAL mean you can open current
# command-line in neovim by pressing v in normal mode
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

$env:Path +=  ";$env:PROGRAMFILES\Open Steno Project\Plover 4.0.0.dev12\"
$env:Path += ';C:\Windows\System32'
$env:Path += ';C:\Program Files\Oracle\VirtualBox\'

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

# Hack for running visual Studio for dotnet framework projects with terminal only
# https://intellitect.com/blog/enter-vsdevshell-powershell/
function Enter-VS {
    # First way I found. This way sources a dll then needs a unique GUID from your visual Studio
    # C:\WINDOWS\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -noe -c "&{Import-Module 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'; Enter-VsDevShell 0e7efad8}"

    # This way is better since you just have to run a powershell script
    # Using the -SkipAutomaticLocation keeps you in your current directory instead of changing
    & 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1' -SkipAutomaticLocation
    Write-Host 'Commands to run to build dotnet framework project'
    Write-Host 'nuget restore'
    Write-Host 'msbuild -p:Configuration=Release # or Debug'
    Write-Host 'msbuild -t:restore # maybe'
}

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

    # # Create a new action that includes the original action plus the new output handling
    # # For whatever reason only [console]::WriteLine() output is visible, Write-Host and Write-Output are not visible
    # $ConsoleWriteLineWrappedAction = {
    #     # Execute the original action and pipe its output
    #     & $Action | ForEach-Object { [console]::WriteLine($_) }
    # }

    # Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier FileCreated -Action $Action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier FileChanged -Action $Action
    # Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier FileDeleted -Action $Action
    # Register-ObjectEvent -InputObject $watcher -EventName Renamed -SourceIdentifier FileRenamed -Action $Action

    Write-Host "Monitoring changes to files in $Path with filter $Filter..."
    Write-Host 'Press CTRL+C to stop.'
}
