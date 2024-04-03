BeforeAll {
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath).Replace('.Tests', '')
    $scriptPath = Get-ChildItem "$HOME/MyCrossPlatformScripts/" -Recurse -Filter "$scriptName.ps1"
    | Where-Object FullName -NotMatch 'Tests'
    | Select-Object -First 1 -ExpandProperty FullName
    if ($scriptPath) {
        . $scriptPath
    } else {
        Write-Error "Expected script not found for: $scriptName"
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
