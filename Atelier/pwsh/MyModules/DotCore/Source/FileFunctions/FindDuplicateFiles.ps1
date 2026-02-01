<#
.DESCRIPTION
Find duplicate files
https://stackoverflow.com/a/58677703/9842112
#>
function Find-DuplicateFile
{
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string]$Path = $PWD
    )
    Get-ChildItem -Recurse -File -Path $Path
    | Group-Object -Property Length
    | Where-Object { $_.Count -gt 1 }
    | ForEach-Object { $_.Group }
    | Get-FileHash
    | Group-Object -Property Hash
    | Where-Object { $_.Count -gt 1 }
    | ForEach-Object { $_.Group }
}
