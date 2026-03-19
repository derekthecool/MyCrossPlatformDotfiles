$Script:CGA_Top = 'https://exchange.prx.org'
$Script:CGA_Home = "$($Script:CGA_Top)/series/31235-classical-guitar-alive"

function Get-ClassicalGuitarAlive
{
    [CmdletBinding()]
    [Alias('cga')]
    param ()

    # From the top page, get all the links to the individual weeks program
    $allWeeks = scrape $Script:CGA_Home -QuerySelectorFilter 'div.title a' |
        ForEach-Object { "$($Script:CGA_Top)$($_.PathName)" }

    Write-Verbose "allWeeks:`n$($allWeeks | Out-String)"

    $first = $allWeeks | Select-Object -First 1

    Write-Verbose "first: $($first | Out-String)"

    $firstWeek = scrape https://exchange.prx.org/pieces/611281?m=false 'tr' | text
    $tableHeaders = @(($firstWeek | Select-Object -First 1) -split '\s+')
    Write-Verbose "tableHeaders: $($tableHeaders | Join-String -Separator ', ')"
}
