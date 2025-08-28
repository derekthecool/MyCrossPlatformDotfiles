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
    $OutputTrasactions = Get-Tithing -TithingCsv ./oct262024_feb262025_tithing.csv -Filter tax, REIMBURSED
#>
function Get-Tithing
{
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('\.csv$')]
        [string]$TithingCsv,
        [string[]]$AdditionalFilters
    )

    if (-not (Test-Path $TithingCsv))
    {
        throw "File $TithingCsv not found"
    }

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
    Write-Host "exclude_pattern: $exclude_pattern"
    $transactions = $transactions_raw | Where-Object { $_.Description -notmatch $exclude_pattern }

    $total = ($transactions | Measure-Object -Property Credit -Sum).Sum
    $tithing = $total * 0.12
    Write-Host "Total credit found: $($total.ToString('C'))" -ForegroundColor Green
    Write-Host "Total tithing: $($tithing.ToString('C'))" -ForegroundColor Cyan

    $transactions
}
