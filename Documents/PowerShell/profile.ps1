# PowerShell 7 (pwsh) profile

#region Basic Settings
$env:POWERSHELL_TELEMETRY_OPTOUT = $true

# Add my custom powershell modules to the psmodulepath
# Make sure to use PathSeparator because windows uses ';' and Linux uses ':'
$env:PSModulePath += "$([System.IO.Path]::PathSeparator)$HOME/Atelier/pwsh/MyModules/"

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

    # if (Test-Path '/home/linuxbrew' -ErrorAction SilentlyContinue)
    # {
    #     Invoke-Expression (& { (/home/linuxbrew/.linuxbrew/bin/brew shellenv | Out-String) })
    # }
}
#endregion

#region Find-Program Function
function Find-Program
{
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Program,

        [Parameter(Mandatory = $false, Position = 1)]
        [string[]]$PossiblePaths
    )

    $PossiblePathsNotNull = $null -ne $PossiblePaths
    Get-Variable Program, PossiblePaths, PossiblePathsNotNull
    if ($PossiblePathsNotNull)
    {
        $result = Test-Path -Path $PossiblePaths
        $AtLeastOnePathFound = ($result | Where-Object { $_ -eq $true }).Length -ge 1
        Get-Variable result, AtLeastOnePathFound
        if ($AtLeastOnePathFound)
        {
            return $true
        }
    }

    $find_program_job = Start-Job -ArgumentList $Program -ScriptBlock {
        param($ProgramName)
        [string]::IsNullOrEmpty((Get-Command -Name $ProgramName -ErrorAction SilentlyContinue).Path) -ne $true
    }

    $MaximumDelaySeconds = 3
    if (Wait-Job -Job $find_program_job -Timeout $MaximumDelaySeconds)
    {
        $result = Receive-Job $find_program_job
        return $result
    } else
    {
        Write-Verbose "Timed out searching for $Program after $MaximumDelaySeconds seconds"
        return $false
    }
}
#endregion

#region Starship
if (Find-Program -Program 'starship' -PossiblePaths "$HOME/scoop/ships/starship*", "/usr/local/bin/starship*")
{
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
}
#endregion

#region Yazi
if (Find-Program -Program 'yazi')
{
    if ($IsWindows)
    {
        # Setup yazi file manager path to file.exe
        # required for image preview
        # https://yazi-rs.github.io/docs/installation/#windows
        $env:YAZI_FILE_ONE = "$HOME\scoop\apps\git\current\usr\bin\file.exe", "$env:PROGRAMFILES\Git\usr\bin\file.exe" | Where-Object { Test-Path $_ } | Select-Object -First 1
    }

    # The default Windows yazi config is: %AppData%\yazi\config
    # which is stupid, so use this to set it the same as Linux
    $env:YAZI_CONFIG_HOME = "$HOME/.config/yazi"

    # Suggested function to set path to where yazi ended upon exit
    function y
    {
        $tmp = [System.IO.Path]::GetTempFileName()
        yazi $args --cwd-file="$tmp"
        $cwd = Get-Content -Path $tmp -Encoding UTF8
        if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path)
        {
            Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
        }
        Remove-Item -Path $tmp
    }
}
#endregion

#region PSFzf
if ((Find-Program -Program 'fzf' -PossiblePaths "$HOME/scoop/ships/starship*", "/usr/local/bin/starship*") -and (Get-Module PSFzf -ErrorAction SilentlyContinue -ListAvailable))
{
    Import-Module PSFzf -Force
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Key Tab -BriefDescription 'Use PSFZF as tab completion helper' -ScriptBlock { Invoke-FzfTabCompletion }
    Set-PSReadLineKeyHandler -Chord Ctrl+m -BriefDescription 'Run PSFZF Invoke-FuzzySetLocation for easier deep navigation' -ScriptBlock { Invoke-FuzzySetLocation }
}
#endregion

#region Zoxide
# Init Zoxide and set cd alias
# Add this to the end of your config file (find it by running echo $profile in PowerShell
if (Find-Program -Program 'zoxide' -PossiblePaths "$HOME/.cargo/bin/zoxide*", "$HOME/scoop/shims/zoxide*")
{
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Set-Alias -Name cd -Value z -Option AllScope -Force -Description 'DotAlias for zoxide special cd'
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
