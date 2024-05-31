$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    # Useful for debugging
    # Write-Output "Starting completion script block"
    # Write-Output "wordToComplete: $wordToComplete"
    # Write-Output "commandAst: $commandAst"
    # Write-Output "cursorPosition: $cursorPosition"

    Get-FlutterCommandsAndNonGlobalOptions -FlutterCommand $commandAst
    | ForEach-Object {
        $item = $_.CommandOrHelp
        [System.Management.Automation.CompletionResult]::new($item, $item, 'ParameterValue', $item)
    }

}

Register-ArgumentCompleter -Native -CommandName flutter -ScriptBlock $scriptblock
