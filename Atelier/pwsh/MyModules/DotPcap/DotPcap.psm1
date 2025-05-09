# Build module with 'dotnet publish` only as needed
$BuildExists = Test-Path $PSScriptRoot/bin -ErrorAction SilentlyContinue

Set-Variable -Name Lang -Option ReadOnly -Value 'C#'

Write-Host "BuildExists: $BuildExists"
Write-Host "env:FORCE_DOT_REBUILD: $env:FORCE_DOT_REBUILD"

if (-not $BuildExists -or $env:FORCE_DOT_REBUILD)
{
    if (-not $(Get-Command dotnet -ErrorAction SilentlyContinue))
    {
        Write-Error "dotnet is installed or found cannot build binary $Lang module $PSScriptRoot"
        return
    }

    Write-Host "Building $Lang binary module $PSScriptRoot"

    dotnet publish $PSScriptRoot/DotPcap.csproj --verbosity normal | Write-Verbose
    if ($LASTEXITCODE -ne 0)
    {
        dotnet --list-sdks
        throw 'dotnet publish error'
        return
    }
}

Get-ChildItem "$PSScriptRoot/bin/Release/net*.0/publish/*.dll" | ForEach-Object {
    $Module = $_
    Write-Host "Loading $Lang dll: $Module"
    Import-Module $Module
}
