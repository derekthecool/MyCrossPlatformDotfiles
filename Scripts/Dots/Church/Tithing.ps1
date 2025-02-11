function Calculate-Tithing
{
    param (
        [Parameter()]
        [ValidatePattern('\.csv$')]
        [string]$TithingCsv
    )

    if (-not (Test-Path $TithingCsv))
    {
        throw "File $TithingCsv not found"
    }

    # Get the ignore patterns
    $ignorePatterns = IgnorePatterns

    $transactions = Import-Csv -Path $TithingCsv
    | Where-Object { $_.Credit }
    | Where-Object { $_.Description -notmatch 'VENMO' -and $_.Description -notmatch 'MOBILE BANKING FUNDS TRANSFER' }

    $transactions | Sort-Object -Property @{ Expression = { [datetime]::Parse($_.Date) } }
    $transactions | Format-Table
    $total = ($transactions | Select-Object -ExpandProperty Credit | Measure-Object -Sum).Sum
    $tithing = $total * 0.12
    Write-Host "Total credit found: $total" -ForegroundColor Green
    Write-Host "Total tithing: $tithing" -ForegroundColor Cyan
}

function IgnorePatterns
{
    return 'MOBILE BANKING FUNDS', 'VENMO'
}
