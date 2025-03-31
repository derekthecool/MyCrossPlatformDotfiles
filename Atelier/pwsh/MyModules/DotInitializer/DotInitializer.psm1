Get-ChildItem $PSScriptRoot/Source -Recurse -Filter '*.ps1' | ForEach-Object {
    Write-Verbose "In $PSScriptRoot, sourcing file $_"
    . $_.FullName
}

# Needed for every OS
Import-Module 'AnyPackage.PSResourceGet'

# Linux only
if($IsLinux -and ($PSVersionTable.OS -match 'Ubuntu'))
{
    Import-Module 'AnyPackage.Apt'
}

# Windows only
if($IsWindows)
{
    Install-Scoop
    Import-Module 'AnyPackage.WinGet', 'AnyPackage.Scoop', 'AnyPackage.Programs'
}

# TODO: (Derek Lomax) Sat 29 Mar 2025 09:01:01 PM MDT, The DotNet.Tool provider is not respecting the priority
