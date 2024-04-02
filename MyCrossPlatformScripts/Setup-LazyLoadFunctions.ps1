function Setup-LazyLoadFunctions {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$LazyLoadFunctions
    )

    foreach ($entry in $LazyLoadFunctions.GetEnumerator()) {
        $functionName = $entry.Key
        $scriptPath = $entry.Value

        Invoke-Expression @"
function Global:$functionName {
    # Remove the placeholder function
    Remove-Item Function:\$functionName

    # Dot-source the script containing the real function
    . `"$scriptPath`"

    # Now call the real function, passing along any arguments
    &$functionName `@args
}
"@
    }
}
