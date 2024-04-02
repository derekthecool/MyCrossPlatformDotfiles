function Setup-LazyLoadFunctions {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$LazyLoadFunctions
    )

    # Ensure global hashtable is initialized
    if (-not $global:FunctionDefinitions) {
        $global:FunctionDefinitions = @{}
    }

    foreach ($entry in $LazyLoadFunctions.GetEnumerator()) {
        $functionName = $entry.Key
        $scriptPath = $entry.Value

        # Incorporate the captured variables directly into the script block
        # Adjusted part within the lazy loading setup where the script block is defined:
        $functionScriptBlock = {
            param($args)

            # Retrieve the script path using the function name
            $scriptPath = $global:FunctionDefinitions["$functionName"]

            # Dot-source the script containing the actual function
            if (Test-Path $scriptPath) {
                . $scriptPath
            } else {
                Write-Error "Script file not found: $scriptPath"
                return
            }

            # After dot-sourcing, directly invoke the loaded function with all arguments
            & $functionName @args
        }.GetNewClosure()

        # Update or add the function definition in the global hashtable
        $global:FunctionDefinitions[$functionName] = $scriptPath

        # Define the function using the script block
        New-Item -Path "Function:Global:$functionName" -Value $functionScriptBlock -ErrorAction SilentlyContinue | Out-Null
    }
}
