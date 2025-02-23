<#
This script started with the 3rd example from the Get-Help -All Register-ArgumentCompleter

Then it has been enhanced to sort the completion items and move ones starting with symbols
to the end of the list
#>
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    # Capture the completion results
    $completionResults = dotnet complete --position $cursorPosition $commandAst.ToString()

    # Define a custom sort order function
    function CustomSortOrder
    {
        param($item)
        if ($item -match '^[a-zA-Z]')
        {
            return 0
        } else
        {
            return 1
        }
    }

    # Sort the completion results using the custom sort order function
    $sortedResults = $completionResults
    | Sort-Object @{
        Expression = { CustomSortOrder $_ }
        Ascending  = $true
    }, @{
        Expression = { $_ }
        Ascending  = $true
    }

    # Create CompletionResult objects from the sorted results
    $sortedResults | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

$env:DOTNET_CLI_TELEMETRY_OPTOUT = $true
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock
