<#
    .SYNOPSIS
    Adds a file name extension to a supplied name.

    .DESCRIPTION
    See more details on running plover from the command line here: https://plover.wiki/index.php/Invoke_Plover_from_the_command_line

    .PARAMETER Name
    Specifies the file name.

    .EXAMPLE
    PS> Add-Extension -name "File"
#>
function Get-PloverPath
{
    switch ($null)
    {
        { $IsWindows }
        {
            return (Get-ChildItem "$env:PROGRAMFILES/Open Steno Project/Plover*/plover_console*").FullName
        }
        { $IsLinux }
        {
            throw 'TODO support Linux appimage path search'
        }
        { $IsMacOS }
        {
            Get-ChildItem "/Applications/Plover.app/Contents/MacOS/Plover"
        }
        default
        {
            throw 'System not supported'
        }
    }
}

function Invoke-Plover
{
    $ploverPath = Get-PloverPath
    if (-not $ploverPath)
    {
        throw 'Could not find plover_console'
    }

    $command = "& '$ploverPath' $args"
    Write-Host "Running plover command: $command" -ForegroundColor Green
    Invoke-Expression $command
}

Set-Alias -Name plover -Value Invoke-Plover
Set-Alias -Name plover_console -Value Invoke-Plover

function Get-PloverConfigurationDirectory
{
    switch ($null)
    {
        { $IsWindows }
        {
            "$env:LOCALAPPDATA/Plover/Plover"
        }
        { $IsLinux }
        {
            "$HOME/.config/plover"
        }
        { $IsMacOS }
        {
            "$HOME/Library/Application Support/plover"
        }
        default
        {
            throw 'unknown plover system'
        }
    }
}

function Get-TapeyTapePath
{
    "$(Get-PloverConfigurationDirectory)/tapey_tape.txt"
}
