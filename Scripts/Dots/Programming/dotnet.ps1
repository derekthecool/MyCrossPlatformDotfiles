function dotnet-ListOutdated
{
    param (
        [Parameter()]
        [switch]$Update
    )

    $packages = dotnet list package --outdated --format json
    | ConvertFrom-Json
    | Select-Object -ExpandProperty projects
    | Select-Object -ExpandProperty frameworks
    | Select-Object -ExpandProperty topLevelPackages

    if($Update)
    {
        $packages | ForEach-Object {
            dotnet remove package $_.id
            dotnet add package $_.id
        }
    }

    $packages
}
