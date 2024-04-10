function Setup-DotnetShellCompletion {
    if(Get-Command dotnet -ErrorAction SilentlyContinue) {
        # Stop dotnet telemetry
        $env:DOTNET_CLI_TELEMETRY_OPTOUT = $true
        # PowerShell parameter completion shim for the dotnet CLI
        Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
            param($commandName, $wordToComplete, $cursorPosition)
            dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        }
    } else {
        Write-Host 'dotnet is not installed or not in path'
    }
}
