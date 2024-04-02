BeforeAll {
    . $PSScriptRoot/../Setup-DotnetTools.ps1
}

Describe 'Setup-DotnetShellCompletion Tests' {

    It 'Sets the DOTNET_CLI_TELEMETRY_OPTOUT environment variable' {
        Setup-DotnetShellCompletion
        $env:DOTNET_CLI_TELEMETRY_OPTOUT | Should -Be $true
    }

    It 'Registers an argument completer for dotnet when dotnet is available' {
        Mock Get-Command { return $true }
        Mock Register-ArgumentCompleter {}

        Setup-DotnetShellCompletion

        Assert-MockCalled Register-ArgumentCompleter -Times 1 -ParameterFilter {
            $CommandName -eq 'dotnet'
        }
    }

    It 'Does not register an argument completer for dotnet when dotnet is not available' {
        Mock Get-Command { return $null }
        Mock Register-ArgumentCompleter {}

        Setup-DotnetShellCompletion

        Assert-MockCalled Register-ArgumentCompleter -Times 0
    }
}
