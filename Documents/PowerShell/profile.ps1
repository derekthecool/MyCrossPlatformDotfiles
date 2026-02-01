# PowerShell 7 (pwsh) profile

#region Basic Settings
# Set output encoding for pwsh spectre console
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$env:POWERSHELL_TELEMETRY_OPTOUT = $true

# Add my custom powershell modules to the psmodulepath
# Make sure to use PathSeparator because windows uses ';' and Linux uses ':'
if ($env:PSModulePath -notmatch 'MyModules')
{
    $env:PSModulePath += "$([System.IO.Path]::PathSeparator)$HOME/Atelier/pwsh/MyModules/"
}
# For module fast
if ($IsWindows)
{
    $env:PSModulePath += "$([System.IO.Path]::PathSeparator)$env:LOCALAPPDATA/powershell/Modules/"
}


# Set editor environment variables
$env:EDITOR = 'nvim'
$env:VISUAL = $env:EDITOR
$EDITOR = $env:EDITOR
#endregion

#region PSDefaultParameterValues
# A true super power of powershell is setting these default parameters!
# They are a bit like aliases but only used if not specified.
$PSDefaultParameterValues = @{
    'Out-Default:OutVariable'           = 'LastResult'         # Save output to $LastResult
    'Out-File:Encoding'                 = 'utf8'               # PS5.1 defaults to ASCII
    'Export-Csv:NoTypeInformation'      = $true                # PS5.1 defaults to $false
    'ConvertTo-Csv:NoTypeInformation'   = $true                # PS5.1 defaults to $false
    'Receive-Job:Keep'                  = $true                # Prevents accidental loss of output
    'Install-Module:AllowClobber'       = $true                # Default behavior in Install-PSResource
    'Install-Module:Force'              = $true                # Default behavior in Install-PSResource
    'Install-Module:SkipPublisherCheck' = $true                # Default behavior in Install-PSResource
    'Find-Module:Repository'            = 'PSGallery'          # Useful if you have private test repos
    'Install-Module:Repository'         = 'PSGallery'          # Useful if you have private test repos
    'Find-PSResource:Repository'        = 'PSGallery'          # Useful if you have private test repos
    'Install-PSResource:Repository'     = 'PSGallery'          # Useful if you have private test repos
    'Import-Module:DisableNameChecking' = $true                # To not warning me of functions or scripts not using verb-noun names
    'Invoke-RestMethod:ContentType'     = 'application/json'   # This is almost always used
    'ConvertTo-Json:Compress'           = $true                # Prefer compact json string formatting
}

#region Aliases
# Alias with args require functions
function rmdir
{
    Remove-Item -Recurse -Force $args
}
Set-Alias -Name rmdir -Value rmdir_function -Option AllScope -Force -Description 'DotAlias for Remove-Item -Recurse -Force'
function diff_function
{
    git diff --no-index $args
}
Set-Alias -Name diff -Value diff_function -Option AllScope -Force -Description 'DotAlias for git diff --no-index $args'

# Linux style aliases I must have
Set-Alias -Name ls -Value Get-ChildItem -Option AllScope -Force -Description 'DotAlias for Get-ChildItem'
Set-Alias -Name cp -Value Copy-Item -Option AllScope -Force -Description 'DotAlias for Copy-Item'
Set-Alias -Name sort -Value Sort-Object -Option AllScope -Force -Description 'DotAlias for Sort-Object'
Set-Alias -Name sleep -Value Start-Sleep -Option AllScope -Force -Description 'DotAlias for Start-Sleep' -Scope Global
Set-Alias -Name ps -Value Get-Process -Option AllScope -Force -Description 'DotAlias for Get-Process'
Set-Alias -Name rm -Value Remove-Item -Option AllScope -Force -Description 'DotAlias for Remove-Item'
Set-Alias -Name kill -Value Stop-Process -Option AllScope -Force -Description 'DotAlias for Stop-Process'
Set-Alias -Name cat -Value Get-Content -Option AllScope -Force -Description 'DotAlias for Get-Content'
Set-Alias -Name clear -Value Clear-Host -Option AllScope -Force -Description 'DotAlias for Clear-Host'
Set-Alias -Name mv -Value Move-Item -Option AllScope -Force -Description 'DotAlias for Move-Item'
Set-Alias -Name tee -Value Tee-Object -Option AllScope -Force -Description 'DotAlias for Tee-Object'
#endregion

#region PSReadLine
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
    EditMode                      = 'Vi'
    ViModeIndicator               = 'Prompt'
}
Set-PSReadLineOption @PSReadLineOptions

$PSStyle.Progress.UseOSCIndicator = $true

# Custom key mappings
# Set-PSReadLineKeyHandler -Chord Ctrl+b -Function YankLastArg
# Set-PSReadLineKeyHandler -Chord Ctrl+w -Function YankNthArg
Set-PSReadLineKeyHandler -Chord Ctrl+u -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+d -Function NextHistory
Set-PSReadLineKeyHandler -Chord × -Function DeleteEndOfBuffer
# Somehow Ctrl+Alt+H  == Backspace. Does not seem to work in a neovim terminal
Set-PSReadLineKeyHandler -Chord Ctrl+Alt+H -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord Ctrl+Shift+y -ScriptBlock {
    Get-History | Select-Object -Last 1 -ExpandProperty CommandLine | Set-Clipboard
    Write-Host "Saved the last command to clipboard"
}

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

Set-PSReadLineKeyHandler -Chord Ctrl+w `
    -BriefDescription UpOneDirectory `
    -LongDescription 'Move up one directory' `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    Push-Location -StackName PSReadLine
    Set-Location ..
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Chord Ctrl+Alt+w `
    -BriefDescription UpOneDirectory `
    -LongDescription 'Move back one directory' `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    Pop-Location -StackName PSReadLine
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
#endregion

#region Linux permanent environment variable processor
if ($IsLinux)
{
    $CurrentPath = $env:PATH -split [IO.Path]::PathSeparator
    Get-Content $PSScriptRoot/AdditionalPathItems_Linux.txt | ForEach-Object {
        $Item = $_
        if ([string]::IsNullOrEmpty($Item) -eq $false -and $CurrentPath -notcontains $Item)
        {
            $env:PATH += [IO.Path]::PathSeparator + $Item
        }
    }
}
#endregion

#region Starship
# Roughly 1000 ms load time for this
try
{
    # Fail fast if starship is not found - do not run the recommended double Invoke-Expression
    # website shows this: Invoke-Expression (&starship init powershell)
    # 200 ms
    $init = starship init powershell

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
    # 800 ms
    Invoke-Expression ($init)
} catch
{
    Write-Host "starship not found" -ForegroundColor Yellow
}
#endregion

#region PSFzf
try
{
    Import-Module PSFzf -Force
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Key Tab -BriefDescription 'Use PSFZF as tab completion helper' -ScriptBlock {
        Invoke-FzfTabCompletion
    }
    Set-PSReadLineKeyHandler -Chord Ctrl+m -BriefDescription 'Run PSFZF Invoke-FuzzySetLocation for easier deep navigation' -ScriptBlock {
        Invoke-FuzzySetLocation
    }
} catch
{
    Write-Host "PSFzf or fzf not found" -ForegroundColor Yellow
}
#endregion

#region Zoxide
# Init Zoxide and set cd alias
# Add this to the end of your config file (find it by running echo $profile in PowerShell
try
{
    zoxide init powershell | Out-String | Invoke-Expression
    Set-Alias -Name cd -Value z -Option AllScope -Force -Description 'DotAlias for zoxide special cd'
} catch
{

    Write-Host "zoxide not found" -ForegroundColor Yellow
}
#endregion


# Load git related powershell modules upon first call to git, then remove this function
function git
{
    Remove-Item -Path Function:\git -ErrorAction SilentlyContinue
    # Import-Module ugit
    Import-Module posh-git

    Invoke-Expression "git $args"
}

Import-Module Posh

Write-Host "Profile load: $([int]((Get-Date) - (Get-Process -Id $PID).StartTime).TotalMilliseconds) ms" -ForegroundColor Cyan
