Write-Output "Current location is: $PSScriptRoot"

$modules = Get-ChildItem "./Dots/Dots.psd1"
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
    Install-Module -Name $_.Name -MaximumVersion $_.Version
}
