Get-ChildItem $PSScriptRoot/Source -Recurse -Filter '*.ps1' | ForEach-Object {
    Write-Verbose "In $PSScriptRoot, sourcing file $_"
    . $_.FullName
}

$PSXmlFormatFile = Resolve-Path "$PSScriptRoot/*.format.ps1xml"
if ($PSXmlFormatFile)
{
    $EzOutBuildScript = Resolve-Path "$PSScriptRoot/*.EzFormat.ps1"
    Write-Host "EzOutBuildScript: $($EzOutBuildScript.Path), env:DotEZOutBuildOnImport: $env:DotEZOutBuildOnImport"
    if ($EzOutBuildScript -and $env:DotEZOutBuildOnImport)
    {
        Write-Host "Building format files with ezout script: $($EzOutBuildScript.Path)"
        & $EzOutBuildScript.Path
    }

    Write-Host "Loading $($PSXmlFormatFile.Path) format file"
    Update-FormatData -PrependPath $PSXmlFormatFile.Path
}
