function Get-DotPSMDTemplate
{
    Get-PSMDTemplate -Store Default
}

function Update-DotPSMDTemplate
{
    # Remove all templates before continuing
    Get-DotPSMDTemplate | ForEach-Object {
        Remove-PSMDTemplate -TemplateName $_.Name -Confirm:$false
    }

    Get-ChildItem $HOME/Atelier/pwsh/PSModuleDevelopmentTemplates/ -Directory | ForEach-Object {
        Write-Verbose "Attempting to load directory: $_ as a PSMD project template"
        New-PSMDTemplate -ReferencePath $_.FullName
    }

    Get-DotPSMDTemplate
}
