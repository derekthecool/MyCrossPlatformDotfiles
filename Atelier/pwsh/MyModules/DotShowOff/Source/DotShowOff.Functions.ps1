function Show-Object
{
    param (
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )

    process
    {
        $json = $InputObject | ConvertTo-Json -Depth 10
        & dotnet run --project $PSScriptRoot/../ShowOffTUI/ShowOffTUI.csproj -- $json
    }
}

New-Alias -Name 'Show' -Value Show-Object
