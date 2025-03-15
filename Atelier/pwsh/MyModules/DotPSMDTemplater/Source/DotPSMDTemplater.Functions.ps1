<#
    .SYNOPSIS
    Get the custom templates created in these Dotfiles

    .DESCRIPTION
    Get the custom templates created in these Dotfiles

    .EXAMPLE
    Get-DotPSMDTemplate
#>
function Get-DotPSMDTemplate
{
    Get-PSMDTemplate -Store Default
}

<#
    .SYNOPSIS
    Delete all of my templates and load the latest version

    .DESCRIPTION
    This function makes Get-PSMDTemplate work the way I want it to with my templates

    .PARAMETER Path
    Optionally specify the path. Default is specified for local use already which references
    the where all the templates are stored in this repository.
    But to make this more testable via CI testing this parameter is supplied.
    This repository is designed to be run as a git bare repository and testing
    in a GH action assumes normal repository cloning.

    .EXAMPLE
    Update-DotPSMDTemplate
#>
function Update-DotPSMDTemplate
{
    param (
        [string]$Path = "$HOME/Atelier/pwsh/PSModuleDevelopmentTemplates/"
    )

    # Remove all templates before continuing
    Get-DotPSMDTemplate | ForEach-Object {
        Remove-PSMDTemplate -TemplateName $_.Name -Confirm:$false
    }

    Get-ChildItem -Directory -Path $Path | ForEach-Object {
        Write-Verbose "Attempting to load directory: $_ as a PSMD project template"
        New-PSMDTemplate -ReferencePath $_.FullName
    }

    Get-DotPSMDTemplate
}
