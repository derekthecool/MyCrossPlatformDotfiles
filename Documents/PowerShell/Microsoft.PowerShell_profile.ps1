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

# # # Load these configuration items now (not lazy loaded)
# . "$HOME/MyCrossPlatformScripts/Invoke-DotGit.ps1"

# Add my custom powershell modules to the psmodulepath
# Make sure to use PathSeparator because windows uses ';' and Linux uses ':'
$env:PSModulePath += "$([System.IO.Path]::PathSeparator)$HOME/Scripts/"

# Proxy function to load my powershell module when needed
# This function will delete itself and the proper one will be loaded
function dot {
    # Delete this proxy function
    Remove-Item function:\dot

    # Import the module
    # -Force helps to always load the latest version
    # -DisableNameChecking ignores warnings about unapproved verbs
    Import-Module "$HOME/Scripts/Dots/Dots.psd1" -Force -DisableNameChecking

    # Call the new function so the first call is not noticeably different
    dot $args
}
