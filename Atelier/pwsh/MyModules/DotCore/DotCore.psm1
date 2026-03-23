Get-ChildItem $PSScriptRoot/Source -Recurse -Filter '*.ps1' | ForEach-Object {
    Write-Verbose "In $PSScriptRoot, sourcing file $_"
    . $_.FullName
}

# TODO: (Derek Lomax) 3/17/2026 3:29:35 PM, add this as a module template item and luasnip snippet
$root = $PSScriptRoot
$PSXmlFormatFile = Resolve-Path "$root/*.format.ps1xml"
$LastTimeFormatFileChanged = Get-ChildItem "$root/Formatting" -Recurse -File |
    Select-Object -ExpandProperty LastWriteTime
$LastTimePS1XMLChanged = (Get-ChildItem $PSXmlFormatFile).LastWriteTime

if ($LastTimeFormatFileChanged -gt $LastTimePS1XMLChanged)
{
    Write-Host "Regenerating format.ps1xml because newer format file detected"
    $EzOutBuildScript = Resolve-Path "$root/*.EzFormat.ps1"
    & $EzOutBuildScript.Path
    # The ps1xml would have already been loaded via the psd1 FormatsToProcess
    # but if regenerating reloading like this is necessary else the module must
    # be imported a second time
    Update-FormatData -PrependPath $PSXmlFormatFile.Path
}
