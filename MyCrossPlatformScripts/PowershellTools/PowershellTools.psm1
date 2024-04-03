# Dot source all local scripts
Write-Verbose "Getting ready to dot source files from $PSScriptRoot" -Verbose
Get-ChildItem "$PSScriptRoot/*.ps1" -Recurse | ForEach-Object {
    Write-Verbose "Sourcing: $($_.FullName)" -Verbose
    . $_.FullName
}

# Add these items to the path
Add-MasonToolsToPath
