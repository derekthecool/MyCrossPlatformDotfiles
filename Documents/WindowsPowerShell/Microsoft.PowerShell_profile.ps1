#Personal settings

# Stop dotnet telemetry
$env:DOTNET_CLI_TELEMETRY_OPTOUT = $true

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
$env:Path +=  ";$env:LOCALAPPDATA\programs\Open Steno Project\Plover 4.0.0.dev10+82.g2012d4b\"
$env:Path += ';C:\Windows\System32'
$env:Path += ';C:\Program Files\Oracle\VirtualBox\'

Set-Alias 'v' 'nvim'

$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(271, 9999)

function fm {
& $env:USERPROFILE\source\repos\FreeusMicronTools\fm-cli\bin\Release\net6.0\win10-x64\publish\fm-cli.exe
}

function Read-History {
    Get-Content (Get-PSReadLineOption).HistorySavePath
}

function vim ($File) {
    $File = $File -replace "\\", "/" -replace " ", "\ "
    bash -c "nvim $File"
}
$WallabyFunctionsScript = Join-Path -Path (Get-Item $PROFILE).DirectoryName -ChildPath "Scripts\Wallaby\WallabyFunctions.ps1"
. $WallabyFunctionsScript

$CATM1FunctionsScript = Join-Path -Path (Get-Item $PROFILE).DirectoryName -ChildPath "Scripts\CAT1M1\CAT1M1-Functions.ps1"
. $CATM1FunctionsScript

# Set Starship prompt
$ENV:STARSHIP_CONFIG = "$HOME\.starship\config.toml"
Invoke-Expression (&starship init powershell)

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

function Source-Espidf(){
    # Set environment variable to esp-idf-v5
    $env:IDF_PATH = 'C:\Espressif\frameworks\esp-idf-v5.0'

    # Command as seen in the desktop shortcut, way to long and it messes up your CWD
    # pwsh -ExecutionPolicy Bypass -NoExit -File "C:\Espressif/Initialize-Idf.ps1" -IdfId esp-idf-121ffdbe0b35e1365bcc6c7122ca4a7a

    # Run the script
    C:\Espressif/Initialize-Idf.ps1
}
