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
    'posh-git'
    @{
        ModuleName    = 'SimplySql'; ModuleVersion = '2.0.3.73'
    },
    @{
        ModuleName    =  'Profiler'; ModuleVersion = '4.3.0'
    }

    #region AnyPackage
    'AnyPackage'
    'AnyPackage.WinGet'
    'AnyPackage.Scoop'
    'AnyPackage.PSResourceGet'
    'AnyPackage.Programs'
    'AnyPackage.DotNet.Tool'
    'AnyPackage.Apt'

    # Available official anypackage providers that I don't want
    # 'AnyPackage.Wsl'
    # 'AnyPackage.Pkgx'
    # 'AnyPackage.NuGet'
    # 'AnyPackage.Msu'
    # 'AnyPackage.Msi'
    # 'AnyPackage.ModuleFast'
    # 'AnyPackage.Homebrew'
    # 'AnyPackage.Chocolatey'
    #endregion
)


# Convert module entries to a consistent format and install them
$RequiredModules | ForEach-Object {
    if ($_ -is [string])
    {
        Install-Module -Name $_ -Scope CurrentUser -Force -AllowClobber
    } else
    {
        Install-Module -Name $_.ModuleName -RequiredVersion $_.ModuleVersion -Scope CurrentUser -Force -AllowClobber
    }
}

Get-Module -All
