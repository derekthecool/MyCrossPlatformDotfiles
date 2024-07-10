Write-Output "Current location is: $PSScriptRoot"

$modules = Get-ChildItem -Recurse 'Dots.psd1'
| Select-String -AllMatches -Pattern "ModuleName\s*=\s*'(?<Name>[a-zA-Z0-9.-]+)';\s*ModuleVersion\s*=\s*'(?<Version>.*?)'"
| Select-Object -ExpandProperty Matches
| ForEach-Object {
    $Name = $_.Groups['Name']
    $Version = $_.Groups['Version']
    [PSCustomObject]@{Name = $Name;Version = $Version}
  }

Write-Host "Modules found"
$modules

$modules | ForEach-Object {
    Write-Host "Installing $($_.Name)"
    Install-Module -Name $_.Name -MaximumVersion $_.Version -Force -SkipPublisherCheck
    Write-Host "Importing $($_.Name)"
    Import-Module -Name $_.Name
}

Get-Module -All
