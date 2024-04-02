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
. "$HOME/MyCrossPlatformScripts/Invoke-DotGit.ps1"
. "$HOME/MyCrossPlatformScripts/Setup-LazyLoadFunctions.ps1"

# Call function function lazy load dot sourced scripts
# Initial setup cut my startup time from 1223ms to 700ms
Setup-LazyLoadFunctions -LazyLoadFunctions @{
    'Setup-DotnetTools' = "$HOME/MyCrossPlatformScripts/Setup-DotnetTools.ps1"
    'Add-MasonToolsToPath' = "$HOME/MyCrossPlatformScripts/NeovimRelated/Add-MasonToolsToPath.ps1"
    'Get-TopMemoryProcesses' = "$HOME/MyCrossPlatformScripts/Get-TopMemoryProcesses.ps1"
    'Watch-FileChange' = "$HOME/MyCrossPlatformScripts/Watch-FileChange.ps1"
    'Source-Espidf' = "$HOME/MyCrossPlatformScripts/Source-ESPIDF.ps1"
    'Invoke-GitDiff' = "$HOME/MyCrossPlatformScripts/Invoke-GitDiff.ps1"

    # Windows only
    'Start-VSCompiler' = "$HOME/MyCrossPlatformScripts/Windows/Start-VSCompiler.ps1"
}


# if($IsWindows) {
#     $env:Path +=  ";$env:PROGRAMFILES\Open Steno Project\Plover 4.0.0.dev12\"
#     $env:Path += ';C:\Windows\System32'
#     $env:Path += ';C:\Program Files\Oracle\VirtualBox\'
# }

# gh (GitHub CLI) completion
Invoke-Expression -Command $(gh completion -s powershell | Out-String)
