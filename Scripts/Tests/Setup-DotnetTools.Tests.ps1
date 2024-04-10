BeforeAll {
    # Extract just the filename without extension and replace '.Tests' with nothing, assuming the test script ends with '.Tests.ps1'
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    $scriptName = $fileNameWithoutExtension -replace '\.Tests$', ''
    $scriptFileName = "$scriptName.ps1"
    $scriptBase = ([regex]::Match($PSCommandPath, '(.*[/\\]Scripts)')).Groups[1].Value

    # Search for the script within the base directory, excluding any paths that still include 'Tests'
    $scriptPath = Get-ChildItem -Path $scriptBase -Recurse -Filter $scriptFileName |
        Where-Object { $_.FullName -notmatch 'Tests' } |
        Select-Object -First 1 -ExpandProperty FullName

    if ($scriptPath) {
        . $scriptPath
    } else {
        Write-Error "Expected script not found for: $scriptFileName"
        Write-Error "Script base: $scriptBase"
    }
}

Describe 'Setup-DotnetShellCompletion Tests' {

    It 'Sets the DOTNET_CLI_TELEMETRY_OPTOUT environment variable' {
        Setup-DotnetShellCompletion 2> $null
        $env:DOTNET_CLI_TELEMETRY_OPTOUT | Should -Be $true
    }

    It 'Registers an argument completer for dotnet when dotnet is available' {
        Mock Get-Command { return $true }
        Mock Register-ArgumentCompleter {}

        Setup-DotnetShellCompletion 2> $null

        Assert-MockCalled Register-ArgumentCompleter -Times 1 -ParameterFilter {
            $CommandName -eq 'dotnet'
        }
    }

    It 'Does not register an argument completer for dotnet when dotnet is not available' {
        Mock Get-Command { return $null }
        Mock Register-ArgumentCompleter {}

        Setup-DotnetShellCompletion 2> $null

        Assert-MockCalled Register-ArgumentCompleter -Times 0
    }
}
