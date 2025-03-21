# Build module with 'dotnet publish` only as needed
$BuildExists = Test-Path $PSScriptRoot/bin -ErrorAction SilentlyContinue
$ForceRebuild = $env:FORCE_DOT_REBUILD

Set-Variable -Name Lang -Option ReadOnly -Value 'C#'

function Show-DebugOutputOnError
{
    Write-Host "Building binary $Lang module $PSScriptRoot"
    Write-Host "BuildExists: $BuildExists, $BoundParameters"
    Write-Host "ForceRebuild: $ForceRebuild"
}

if (-not $BuildExists -or $ForceRebuild)
{
    if(-not $(Get-Command dotnet -ErrorAction SilentlyContinue))
    {
        Show-DebugOutputOnError
        Write-Error "dotnet is installed or found cannot build binary $Lang module $PSScriptRoot"
        return
    }

    Write-Host "Building $Lang binary module $PSScriptRoot"

    dotnet publish $PSScriptRoot/*sproj
    if (-not $?)
    {
        Write-Error "Could not build binary $Lang module $PSScriptRoot"
        Show-DebugOutputOnError
        return
    }
}

Get-ChildItem "$PSScriptRoot/bin/Release/net*.0/publish/*.dll" | ForEach-Object {
    $Module = $_
    Write-Host "Loading $Lang dll: $Module"
    Import-Module $Module
}
