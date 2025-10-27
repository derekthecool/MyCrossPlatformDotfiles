Get-ChildItem $PSScriptRoot/Source -Recurse -Filter '*.ps1' | ForEach-Object {
    Write-Verbose "In $PSScriptRoot, sourcing file $_"
    . $_.FullName
}

# One time load for Windows only additional config
if ($IsWindows)
{
    # Setup yazi file manager path to file.exe
    # required for image preview
    # https://yazi-rs.github.io/docs/installation/#windows
    $env:YAZI_FILE_ONE = "$HOME\scoop\apps\git\current\usr\bin\file.exe", "$env:PROGRAMFILES\Git\usr\bin\file.exe" |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1

    # The default Windows yazi config is: %AppData%\yazi\config
    # which is stupid, so use this to set it the same as Linux
    $env:YAZI_CONFIG_HOME = "$HOME/.config/yazi"
}
