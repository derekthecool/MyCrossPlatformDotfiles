Get-ChildItem $PSScriptRoot/Source -Recurse -Filter '*.ps1' | ForEach-Object {
    Write-Verbose "In $PSScriptRoot, sourcing file $_"
    . $_.FullName
}

# Needed for every OS
Import-Module 'AnyPackage.PSResourceGet', 'AnyPackage.DotNet.Tool'

# Linux only
if ($IsLinux -and ($PSVersionTable.OS -match 'Ubuntu'))
{
    Import-Module 'AnyPackage.Apt'
}

if ($IsLinux -or $IsMacOS)
{
    Install-Homebrew
    Import-Module 'AnyPackage.Homebrew'
}


# Windows only
if ($IsWindows)
{
    Install-Scoop

    Import-Module 'AnyPackage.WinGet', 'AnyPackage.Scoop'

    # The programs provider hangs in CI
    if (-not $env:CI)
    {
        Import-Module 'AnyPackage.Programs'
    }
}
