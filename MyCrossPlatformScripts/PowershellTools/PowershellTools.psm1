
& {
    Get-ChildItem "$HOME/MyCrossPlatformScripts/PowershellTools/*.ps1" -Recurse | ForEach-Object {
        Write-Verbose "Sourcing: $($_.FullName)" -Verbose
        . $_.FullName
    }
}

#
# Dot source all local scripts
Write-Verbose "Getting ready to dot source files from $PSScriptRoot" -Verbose
Get-ChildItem "$PSScriptRoot/*.ps1" -Recurse | ForEach-Object {
    Write-Verbose "Sourcing: $($_.FullName)" -Verbose
    . $_.FullName
}


function  Test-DerekModule{
    Write-Output 'Sup'
}
