# Dot source all local scripts
Write-Verbose "Getting ready to dot source files from $PSScriptRoot"

$ExcludeItems = @(
    # Pester tests
    '*Tests*'

    # EZOut items
    '*.format.ps1'
    '*Dots.EzFormat.ps1*'

    # ShowDemo items
    '*Demos*'
    '*.demo.ps1'
)

Get-ChildItem "$PSScriptRoot/*.ps1" -Exclude $ExcludeItems -Recurse
| ForEach-Object {
    Write-Verbose "Sourcing: $($_.FullName)"
    . $_.FullName
}

# Add these items to the path
Add-MasonToolsToPath

# Load the ps1xml format data file here because using the -PrependPath
# option can't be done when loaded via the Dots.psd1 module manifest
# With this option my formatviews become the default views!
Update-FormatData -PrependPath $PSScriptRoot/Dots.format.ps1xml
