# Dot source all local scripts
Write-Verbose "Getting ready to dot source files from $PSScriptRoot"

$ExcludeItems =  @(
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
