Write-Output "Current location is: $PSScriptRoot"

$RequiredModules = @(
    'PSModuleDevelopment'
    'Posh'
    'PSScriptTools'
    'Microsoft.PowerShell.SecretManagement'
    'EZOut'
    'PSFzf'
    'Selenium'
    'Pester'
    @{
        ModuleName    = 'SimplySql'; ModuleVersion = '2.0.3.73'
    },
    @{
        ModuleName    =  'Profiler'; ModuleVersion = '4.3.0'
    }
)


# Convert module entries to a consistent format and install them
$RequiredModules | ForEach-Object {
    if ($_ -is [string])
    {
        Install-Module -Name $_ -Scope CurrentUser -Force
    } else
    {
        Install-Module -Name $_.ModuleName -RequiredVersion $_.ModuleVersion -Scope CurrentUser -Force
    }
}
# $modules | ForEach-Object {
#     Write-Host "Installing $($_.Name)"
#     Install-Module -Name $_.Name -MaximumVersion $_.Version -Force -SkipPublisherCheck
#     Write-Host "Importing $($_.Name)"
#     Import-Module -Name $_.Name
# }
Get-Module -All
