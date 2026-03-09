function Get-DotnetOutdatedPackage
{
    [CmdletBinding()]
    [Alias('dotnet-GetOutdated')]
    param (
        [Parameter()]
        [switch]$Update
    )

    $packages = dotnet list package --outdated --format json

    if (-not $packages)
    {
        throw "running dotnet list package --outdated --format json failed with code $LASTEXITCODE"
    }

    $parsedPackages = $packages |
        ConvertFrom-Json |
        Select-Object -ExpandProperty projects |
        Select-Object -ExpandProperty frameworks |
        Select-Object -ExpandProperty topLevelPackages

    if ($Update)
    {
        $parsedPackages | ForEach-Object {
            dotnet remove package $_.id
            dotnet add package $_.id
        }
    }

    $parsedPackages
}
