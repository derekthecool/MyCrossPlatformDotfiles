# Native argument completer for gcc. Reuses Get-GeneralCompletion from DotCompleter
# so we don't duplicate the --help parsing logic.
Import-Module DotCompleter -ErrorAction SilentlyContinue

$gccCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    Get-GeneralCompletion -Command $commandAst
    | ForEach-Object {
        $item = $_.CommandOrHelp

        $CompletionResultValues = @{
            CompletionText = $item
            ListItemText   = $item
            ResultType     = 'ParameterName'
            ToolTip        = $item
        }

        [System.Management.Automation.CompletionResult]::new(
            $CompletionResultValues['CompletionText'],
            $CompletionResultValues['ListItemText'],
            $CompletionResultValues['ResultType'],
            $CompletionResultValues['ToolTip'])
    }
}

Register-ArgumentCompleter -Native -CommandName gcc -ScriptBlock $gccCompleter
