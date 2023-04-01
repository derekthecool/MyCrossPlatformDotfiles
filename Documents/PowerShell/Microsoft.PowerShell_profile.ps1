# Personal settings
# PowerShell 7 (pwsh)

# [System.Console]::Title = "pwsh v$($PSVersionTable.PSVersion.ToString())"

# Function to using my git bare repo for my windows config files
function dot{git --git-dir="$env:USERPROFILE\.cfg" --work-tree="$env:USERPROFILE" $args}

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
Set-PsReadlineOption -EditMode vi
Set-PSReadLineOption -ViModeIndicator Prompt
Set-PsReadlineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

$env:Path +=  ";$env:PROGRAMFILES\Open Steno Project\Plover 4.0.0.dev12\"
$env:Path += ';C:\Windows\System32'
$env:Path += ';C:\Program Files\Oracle\VirtualBox\'

Set-Alias 'v' 'nvim'

# Hack for running visual Studio for dotnet framework projects with terminal only
function Enter-VS {
    C:\WINDOWS\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -noe -c "&{Import-Module 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'; Enter-VsDevShell 0e7efad8}"
    Write-Host "Run msbuild -p:Configuration=Release"
}

# TODO: find a way to auto source scripts in a known directory 2023-03-09
# Add additional folders to path variable to make it easier to call scripts
# $env:Path += ";$env:USERPROFILE\Documents\WindowsPowerShell\Scripts\Wallaby"
# $env:Path += ";$env:USERPROFILE\Documents\WindowsPowerShell\Scripts\CATM1"

# $WallabyFunctionsScript = Join-Path -Path "$env:USERPROFILE\Documents\WindowsPowerShell" -ChildPath "Scripts\Wallaby\WallabyFunctions.ps1"
# & "$WallabyFunctionsScript"
#
# $CATM1FunctionsScript = Join-Path -Path "$env:USERPROFILE\Documents\WindowsPowerShell" -ChildPath "Scripts\CAT1M1\CAT1M1-Functions.ps1"
# & "$CATM1FunctionsScript"

# Set Starship prompt
# Support for OSC7 (CWD detector or wezterm terminal emulator)
$prompt = ""
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"

        # OSC 7
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}
$ENV:STARSHIP_CONFIG = "$env:USERPROFILE\.starship\config.toml"
Invoke-Expression (&starship init powershell)


# gh (GitHub CLI) completion
Invoke-Expression -Command $(gh completion -s powershell | Out-String)

function Update-Nvim_stimpack_config {
Push-Location .
cd $env:LOCALAPPDATA\nvim && git pull || Write-Host 'Failed to update' -ForegroundColor Red
Write-Host 'Update success' -ForegroundColor Green
Pop-Location
}

# This function sets all the build environment for ESP-IDF
function Source-Espidf(){
    # Customize these for your install path and version
    $version = '5.0.1'
    $root_location = 'D:\'

    # Set environment variable
    $env:IDF_PATH = "${root_location}Espressif\frameworks\esp-idf-v${version}"

    # Run the setup script
    Invoke-Expression "$root_location}Espressif/Initialize-Idf.ps1"
}

function Get-TopProcesses {
    get-process | Group-Object -Property ProcessName |
    ForEach-Object {
        [PSCustomObject]@{
            ProcessName = $_.Name
            Mem_MB = [math]::Round(($_.Group|Measure-Object WorkingSet64 -Sum).Sum / 1MB, 0)
            ProcessCount = $_.Count
        }
    } | Sort-Object -desc Mem_MB | Select-Object -First 25
}

function rename_wezterm_title($title) {
  echo "$([char]27)]1337;SetUserVar=panetitle=$([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($title)))$([char]7)"
}
