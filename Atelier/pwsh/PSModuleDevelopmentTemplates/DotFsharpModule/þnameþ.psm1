# Build module if needed not found or if -Force arg found
$BuildExists = Test-Path $PSScriptRoot/bin -ErrorAction SilentlyContinue
$ForceRebuild = $env:FORCE_DOT_REBUILD

Set-Variable -Name Lang -Option ReadOnly -Value 'F#'

Write-Verbose "Building binary $Lang module $PSScriptRoot"
Write-Verbose "BuildExists: $BuildExists, $BoundParameters"
Write-Verbose "ForceRebuild: $ForceRebuild"

if(-not $BuildExists -or $ForceRebuild)
{
    Write-Verbose "Building $Lang binary module $PSScriptRoot"
    dotnet publish $PSScriptRoot/*sproj
    if(-not $?)
    {
        Write-Error "Could not build binary $Lang module $PSScriptRoot"
        return
    }
}

Get-ChildItem "$PSScriptRoot/bin/Release/net*.0/publish/*.dll" | ForEach-Object {
    $Module = $_
    Write-Verbose "Loading $Lang dll: $Module"
    Import-Module $Module
}
