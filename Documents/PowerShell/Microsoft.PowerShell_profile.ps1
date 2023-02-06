# Personal settings
# PowerShell 7 (pwsh)

[System.Console]::Title = "PowerShell 7"

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

# Add additional folders to path variable to make it easier to call scripts
$env:Path += ";$env:USERPROFILE\Documents\WindowsPowerShell\Scripts\Wallaby"
$env:Path += ";$env:USERPROFILE\Documents\WindowsPowerShell\Scripts\CATM1"
$env:Path += ';C:\Users\Derek Lomax\scoop\apps\netcoredbg\2.0.0-895\'
# $env:Path +=  ";$env:LOCALAPPDATA\programs\Open Steno Project\Plover 4.0.0.dev10+82.g2012d4b\"
$env:Path +=  ";$env:LOCALAPPDATA\programs\Open Steno Project\Plover 4.0.0.dev12\"
$env:Path += ';C:\Windows\System32'
$env:Path += ';C:\Program Files\Oracle\VirtualBox\'

Set-Alias 'v' 'nvim'

function Enter-VS {
    C:\WINDOWS\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -noe -c "&{Import-Module 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'; Enter-VsDevShell 0e7efad8}"
    Write-Host "Run msbuild -p:Configuration=Release"
}

$WallabyFunctionsScript = Join-Path -Path "$env:USERPROFILE\Documents\WindowsPowerShell" -ChildPath "Scripts\Wallaby\WallabyFunctions.ps1"
& "$WallabyFunctionsScript"

$CATM1FunctionsScript = Join-Path -Path "$env:USERPROFILE\Documents\WindowsPowerShell" -ChildPath "Scripts\CAT1M1\CAT1M1-Functions.ps1"
& "$CATM1FunctionsScript"

# Set Starship prompt
$ENV:STARSHIP_CONFIG = "$HOME\.starship\config.toml"
Invoke-Expression (&starship init powershell)

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

function Update-Nvim_stimpack_config {
Push-Location .
cd $env:LOCALAPPDATA\nvim && git pull || Write-Host 'Failed to update' -ForegroundColor Red
Write-Host 'Update success' -ForegroundColor Green
Pop-Location
}

function Source-Espidf(){
    # Set environment variable to esp-idf-v5
    $env:IDF_PATH = 'C:\Espressif\frameworks\esp-idf-v5.0'

    # Command as seen in the desktop shortcut, way to long and it messes up your CWD
    # pwsh -ExecutionPolicy Bypass -NoExit -File "C:\Espressif/Initialize-Idf.ps1" -IdfId esp-idf-121ffdbe0b35e1365bcc6c7122ca4a7a

    # Run the script
    C:\Espressif/Initialize-Idf.ps1
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
