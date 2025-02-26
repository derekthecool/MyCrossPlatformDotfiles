<#
    .SYNOPSIS
    Calculate tithing from a CSV file input

    .DESCRIPTION
    Easily calculate tithing from an input CSV file

    .PARAMETER TithingCsv
    This input file is required

    .PARAMETER Filiter
    This [string] variable allows for multiple filters in the from of 'one|two|three'

    .EXAMPLE
    $OutputTrasactions = Get-Tithing -TithingCsv ./oct262024_feb262025_tithing.csv -Filter 'tax|REIMBURSED'
    $OutputTrasactions | select Description, Credit
#>
function Get-Tithing
{
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('\.csv$')]
        [string]$TithingCsv,
        [string]$Filter
    )

    if (-not (Test-Path $TithingCsv))
    {
        throw "File $TithingCsv not found"
    }

    $transactions = Import-Csv -Path $TithingCsv
    | Where-Object { $_.Credit }
    | Where-Object { $_.Description -notmatch 'VENMO' -and $_.Description -notmatch 'MOBILE BANKING FUNDS TRANSFER' }
    | Where-Object { $_.Description -notmatch $Filter }

    $transactions | Sort-Object -Property @{ Expression = { [datetime]::Parse($_.Date) } }
    $transactions | Format-Table
    $total = ($transactions | Select-Object -ExpandProperty Credit | Measure-Object -Sum).Sum
    $tithing = $total * 0.12
    Write-Host "Total credit found: $total" -ForegroundColor Green
    Write-Host "Total tithing: $tithing" -ForegroundColor Cyan

    $transactions
}
