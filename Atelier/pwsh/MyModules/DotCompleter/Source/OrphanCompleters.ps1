# Register generic --help-parsing completers for CLI tools that have no
# dedicated Dot* module. Each registration uses Get-GeneralCompletion to
# parse the tool's --help output at completion time.
$scriptblock = {
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

$orphanCliTools = @(
    'mosquitto_sub'
    'mosquitto_pub'
    'lftp'
    'curl'
    'grep'
    'lua'
)

$orphanCliTools
| ForEach-Object {
    Register-ArgumentCompleter -Native -CommandName "$_" -ScriptBlock $scriptblock
}
