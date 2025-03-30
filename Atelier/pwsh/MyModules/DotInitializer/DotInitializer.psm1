Get-ChildItem $PSScriptRoot/Source -Recurse -Filter '*.ps1' | ForEach-Object {
    Write-Verbose "In $PSScriptRoot, sourcing file $_"
    . $_.FullName
}

# Needed for every OS
Import-Module 'AnyPackage.PSResourceGet', 'AnyPackage.DotNet.Tool'

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

$Providers = Get-PackageProvider

# Set all providers priority to 50 instead of 100
$Providers | ForEach-Object{ $_.Priority = 50 }

# Increase important providers
$Providers | Where-Object { $_.Name -match 'Scoop|Apt|PSResourceGet' } | ForEach-Object{ $_.Priority += 25 }

# Decrease less important providers
$Providers | Where-Object { $_.Name -match 'AnyPackage.DotNet.Tool' } | ForEach-Object{ $_.Priority = 0 }
