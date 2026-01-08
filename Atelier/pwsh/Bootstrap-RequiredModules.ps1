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

    # https://github.com/EvotecIT/PSWriteOffice
    # Easily create excel, word, and powerpoint
    'PSWriteOffice'

    # https://github.com/PSModule/Markdown
    # easily create markdown items using simple functions
    'Markdown'

    # https://github.com/cloudbase/powershell-yaml
    # Adds the much needed powershell support for yaml like json (ConvertFrom-Yaml, ConvertTo-Yaml)
    'powershell-yaml'

    # https://github.com/EvotecIT/PSParseHTML
    # Amazing module that helps make web scraping easy
    # Used by ./MyModules/DotWebScrape/
    'PSParseHTML'

    # https://github.com/drewgreenwell/ps-menu
    # Plain is simple tui for selecting items interactively, better than Read-Host!
    'ps-menu'

    # https://pwshspectreconsole.com/
    # Great for simple and complexity tuis
    'PwshSpectreConsole'

    #region AnyPackage
    'AnyPackage'
    'AnyPackage.WinGet'
    'AnyPackage.Scoop'
    'AnyPackage.PSResourceGet'
    'AnyPackage.Programs'
    'AnyPackage.DotNet.Tool'
    'AnyPackage.Apt'
    'AnyPackage.Homebrew'
    'AnyPackage.ModuleFast'

    # Available official anypackage providers that I don't want
    # 'AnyPackage.Wsl'
    # 'AnyPackage.Pkgx'
    # 'AnyPackage.NuGet'
    # 'AnyPackage.Msu'
    # 'AnyPackage.Msi'
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
