# Personal settings
# PowerShell 7 (pwsh)

# Set Starship prompt
# Config file is located: ~/.config/starship.toml
# Support for OSC7 (CWD detector or wezterm terminal emulator)
$prompt = ""
function Invoke-Starship-PreCommand
{
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem")
    {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}
Invoke-Expression (&starship init powershell)

# Configure PSReadLine. Does not like to be loaded from another script with dot sourcing.
# For configuration help see these resources
# https://github.com/PowerShell/PSReadLine
# https://gist.github.com/rkeithhill/3103994447fd307b68be
# And run the command Get-PSReadLineKeyHandler
# Define PSReadLine options in a hashtable
$PSReadLineOptions = @{
    PredictionSource              = 'HistoryAndPlugin'
    PredictionViewStyle           = 'ListView'
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    BellStyle                     = 'None'
}
Set-PSReadLineOption @PSReadLineOptions

$PSStyle.Progress.UseOSCIndicator = $true

# Some of these PSReadLineOptions cause trouble with Plover stenography on WSL
# so do not load them if running WSL
if (-not $((Get-Content '/proc/version' -ErrorAction SilentlyContinue) -match 'WSL'))
{
    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -ViModeIndicator Prompt
}

# Custom key mappings
Set-PSReadLineKeyHandler -Chord Ctrl+u -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+d -Function NextHistory
Set-PSReadLineKeyHandler -Chord × -Function DeleteEndOfBuffer
# Somehow Ctrl+Alt+H  == Backspace. Does not seem to work in a neovim terminal
Set-PSReadLineKeyHandler -Chord Ctrl+Alt+H -Function BackwardDeleteWord

# Put parentheses around the selection or entire line and move the cursor to after the closing paren
Set-PSReadLineKeyHandler -Chord Ctrl+y `
    -BriefDescription ParenthesizeSelection `
    -LongDescription 'Put parentheses around the selection or entire line and move the cursor to after the closing parenthesis' `
    -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        $replacement = '(' + $line.SubString($selectionStart, $selectionLength) + ')'
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $replacement)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

# PSFzf mappings
try
{
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
} catch
{
    Write-Host 'PsFzf Is not installed, installing now' -ForegroundColor Red
    Install-Module -Force PSFzf
}

# Init Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue)
{
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Remove-Alias cd -ErrorAction SilentlyContinue
    New-Alias -Name cd -Value z
}

# Set editor environment variables
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

$PSDefaultParameterValues = @{
    'Out-Default:OutVariable'           = 'LastResult'         # Save output to $LastResult
    'Out-File:Encoding'                 = 'utf8'        # PS5.1 defaults to ASCII
    'Export-Csv:NoTypeInformation'      = $true         # PS5.1 defaults to $false
    'ConvertTo-Csv:NoTypeInformation'   = $true         # PS5.1 defaults to $false
    'Receive-Job:Keep'                  = $true         # Prevents accidental loss of output
    'Install-Module:AllowClobber'       = $true         # Default behavior in Install-PSResource
    'Install-Module:Force'              = $true         # Default behavior in Install-PSResource
    'Install-Module:SkipPublisherCheck' = $true         # Default behavior in Install-PSResource
    #'Group-Object:NoElement'            = $true         # Minimize noise in output
    'Find-Module:Repository'            = 'PSGallery'   # Useful if you have private test repos
    'Install-Module:Repository'         = 'PSGallery'   # Useful if you have private test repos
    'Find-PSResource:Repository'        = 'PSGallery'   # Useful if you have private test repos
    'Install-PSResource:Repository'     = 'PSGallery'   # Useful if you have private test repos
    'Import-Module:DisableNameChecking' = $true         # To not warning me of functions or scripts not using verb-noun names
}

# Add my custom powershell modules to the psmodulepath
# Make sure to use PathSeparator because windows uses ';' and Linux uses ':'
$env:PSModulePath += "$([System.IO.Path]::PathSeparator)$HOME/Scripts/"

if ($IsLinux)
{
    # Set aliases to match windows default Linux friendly aliases
    # Get-ChildItem is far better than /usr/bin/ls
    Set-Alias -Name ls -Value Get-ChildItem
    Set-Alias -Name cp -Value Copy-Item
    Set-Alias -Name sort -Value Sort-Object
    Set-Alias -Name sleep -Value Start-Sleep
    Set-Alias -Name ps -Value Get-Process
    Set-Alias -Name rmdir -Value Remove-Item
    Set-Alias -Name kill -Value Stop-Process

    function Add-ToPath
    {
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [string]$NewPathItem
        )
        Process
        {
            $env:PATH += [IO.Path]::PathSeparator + $NewPathItem
        }
    }

    Get-Content $PSScriptRoot/AdditionalPathItems_Linux.txt
    | Add-ToPath
}

# Load git related powershell modules upon first call to git, then remove this function
function git
{
    Remove-Item -Path Function:\git -ErrorAction SilentlyContinue
    # Import-Module ugit
    Import-Module posh-git

    Invoke-Expression "git $args"
}

Import-Module Posh
