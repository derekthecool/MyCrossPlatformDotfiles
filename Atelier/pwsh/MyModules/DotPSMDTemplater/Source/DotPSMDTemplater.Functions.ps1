function Get-DotPSMDTemplate
{
    Get-PSMDTemplate -Store Default
}

function Update-DotPSMDTemplate
{
    Get-ChildItem $HOME/Atelier/pwsh/PSModuleDevelopmentTemplates/ -Directory | ForEach-Object {
        Write-Verbose "Attempting to load directory: $_ as a PSMD project template"
        New-PSMDTemplate -ReferencePath $_.FullName
    }

    Get-DotPSMDTemplate
}
