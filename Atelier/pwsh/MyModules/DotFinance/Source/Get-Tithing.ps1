<#
    .SYNOPSIS
    Calculate tithing from a CSV file input

    .DESCRIPTION
    Easily calculate tithing from an input CSV file

    .PARAMETER TithingCsv
    This input file is required

    .PARAMETER Filiter
    This [string[]] variable allows for multiple filters for items to not match

    .EXAMPLE
    Get-Tithing -TithingCsv ./oct262024_feb262025_tithing.csv -Filter tax, REIMBURSED
#>
function Get-Tithing
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$TithingCsv,
        [string[]]$AdditionalFilters
    )

    process
    {
        $exclude_patterns = @(
            'JESUSCHRIST REIMBURSED'
            'ATM DEPOSIT'
            'ITEMS DEPOSITED'
            'MOBILE BANKING FUNDS TRANSFER'

            # Insert provided additional filters here
            if ($AdditionalFilters)
            {
                $AdditionalFilters | ForEach-Object { $_ }
            }
        )

        $transactions_raw = Import-Csv $TithingCsv | Where-Object { $_.Credit } | Select-Object Date, Credit, Description

        $exclude_pattern = $exclude_patterns -join '|'
        $transactions = $transactions_raw | Where-Object { $_.Description -notmatch $exclude_pattern }

        $total = ($transactions | Measure-Object -Property Credit -Sum).Sum
        $tithing = $total * 0.12

        $transactions | Write-Host

        # TODO: (Derek Lomax) 10/17/2025 8:31:19 PM, use a EZout format custom formatter here to show a nicer display!
        [PSCustomObject]@{
            Credit          = $total
            Tithing         = $tithing
            ExcludePatterns = $exclude_pattern
            Path            = $TithingCsv
            Transactions    = $transactions
        }
    }
}
