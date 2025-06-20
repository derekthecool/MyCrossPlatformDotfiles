function Show-Object
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin
    {
        $items = @()
    }

    process
    {
        $items += $InputObject
    }

    end
    {
        $json = $items | ConvertTo-Json -Depth 10 -Compress
        $escapedJson = $json.Replace('"', '\"')  # Escape quotes for shell safety

        & dotnet run --project $PSScriptRoot/../ShowOffTUI/ShowOffTUI.csproj -- "$escapedJson"
    }
}

New-Alias -Name 'Show' -Value Show-Object
