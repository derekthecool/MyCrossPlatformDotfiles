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
    'SimplySql'
    'Profiler'

    # https://github.com/dfinke/ImportExcel
    # Easy excel for powershell
    'ImportExcel'

    # https://github.com/PSModule/Markdown
    # easily create markdown items using simple functions
    'Markdown'

    #region AnyPackage
    'AnyPackage'
    'AnyPackage.WinGet'
    'AnyPackage.Scoop'
    'AnyPackage.PSResourceGet'
    'AnyPackage.Programs'
    'AnyPackage.DotNet.Tool'
    'AnyPackage.Apt'
    'AnyPackage.Homebrew'

    # Available official anypackage providers that I don't want
    # 'AnyPackage.Wsl'
    # 'AnyPackage.Pkgx'
    # 'AnyPackage.NuGet'
    # 'AnyPackage.Msu'
    # 'AnyPackage.Msi'
    # 'AnyPackage.ModuleFast'
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
