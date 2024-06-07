function Get-GeneralCompletion
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Command
    )

    Process
    {
        $helpOutput = Invoke-Expression "$Command --help"
        $helpOutput
        | Where-Object { -not ([string]::IsNullOrEmpty($_)) }
        | ConvertFrom-Text -NoProgress '(?<CommandOrHelp>(-[a-zA-Z0-9-]+|--[a-zA-Z0-9-]+))'
        | Sort-Object -Property CommandOrHelp -Unique
    }
}

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    Get-GeneralCompletion -Command $commandAst
    | ForEach-Object {
        $item = $_.CommandOrHelp

        $CompletionResultValues = @{
            CompletionText      = $item
            ListItemText        = $item
            ResultType          = 'ParameterName'
            ToolTip             = $item
        }

        [System.Management.Automation.CompletionResult]::new(
            $CompletionResultValues['CompletionText'],
            $CompletionResultValues['ListItemText'],
            $CompletionResultValues['ResultType'],
            $CompletionResultValues['ToolTip'])
    }
}

$cliToolsToUseGeneralCompletion = @(
    'mosquitto_sub'
    'mosquitto_pub'
    'gcc'
    'lftp'
    'curl'
    'grep'
    'tshark'
    'lua'
)

$cliToolsToUseGeneralCompletion
| ForEach-Object {
    Register-ArgumentCompleter -Native -CommandName "$_" -ScriptBlock $scriptblock
}

