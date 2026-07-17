function Get-GeneralCompletion
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Command
    )

    process
    {
        $helpCommand = "$Command --help"
        Write-Verbose "helpCommand:`n$helpCommand"
        $helpOutput = Invoke-Expression "$helpCommand" 2>&1
        Write-Verbose "helpOutput:`n$helpOutput"
        $helpOutput
        | Where-Object { -not ([string]::IsNullOrEmpty($_)) }
        | ConvertFrom-Text -NoProgress '^\s{2,}(?<CommandOrHelp>(-[A-Za-z0-9]|-{2}[a-z][a-z0-9-]+))'
        | Sort-Object -Property CommandOrHelp -Unique -CaseSensitive
    }
}
