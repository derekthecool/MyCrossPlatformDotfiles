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

        $CompletionResultValues = @{
            CompletionText = $item
            ListItemText = $item
            ResultType = 'ParameterValue'
            ToolTip = $item
        }

        [System.Management.Automation.CompletionResult]::new(
            $CompletionResultValues['CompletionText'],
            $CompletionResultValues['ListItemText'],
            $CompletionResultValues['ResultType'],
            $CompletionResultValues['ToolTip'])
    }

}

Register-ArgumentCompleter -Native -CommandName flutter -ScriptBlock $scriptblock
