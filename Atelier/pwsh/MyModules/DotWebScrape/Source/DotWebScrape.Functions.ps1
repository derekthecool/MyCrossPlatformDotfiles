<#
    .SYNOPSIS
    Web scraping in powershell made easy

    .DESCRIPTION
    This function uses the module https://github.com/EvotecIT/PSParseHTML which itself includes two
    dotnet packages AngleSharp and HtmlAgilityPack.

    Great web scraping sites to test with include
    - https://proxyway.com/guides/best-websites-to-practice-your-web-scraping-skills
    - https://toscrape.com/
    - https://www.scrapethissite.com/
    - https://sandbox.oxylabs.io/
    - https://crawler-test.com/
    - https://books.toscrape.com/
    - https://quotes.toscrape.com/

    .PARAMETER Url
    Link to site to scrape

    .PARAMETER QuerySelectorFilter
    CSS query selector to filter, defaults to using * which will show all children recursively

    .EXAMPLE
    # Get all Zelda games from this oxylabs demo game page
    # This example shows the power of creating a good query selector to get close and
    # then using powershell pipeline string matching to find only Zelda games
    scrape https://sandbox.oxylabs.io/products "h4.title.css-7u5e79.eag3qlw7" | Where-Object { $_.TextContent -match 'Zelda' }

    .EXAMPLE
    # Get all countries from scrapethissite
    Get-Site https://www.scrapethissite.com/pages/simple/ 'h3.country-name' | Get-SiteText
    # Or using the aliases
    scrape https://www.scrapethissite.com/pages/simple/ 'h3.country-name' | text

    .EXAMPLE
    # Get all error enums from a table
    # Makes use of good css selector and text filtering together and uses the aliases
    scrape https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-guides/lwip.html#socket-error-reason-code 'tr td p' '^[A-Z]+$' | text

    .EXAMPLE
    # get quotes
    s isscrape https://quotes.toscrape.com/ 'span.text' | text
#>
function Get-Site
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$Url,

        # Default to using * for the query filter to select everything recursively
        [Parameter(Position = 1)]
        [string]$QuerySelectorFilter = "*",

        [Parameter(Position = 2)]
        [string]$BasicTextFilter = ".*"
    )

    $result = ConvertFrom-Html -Url $Url -Engine AngleSharp
    $result.Children[1].Children.QuerySelectorAll($QuerySelectorFilter) | Where-Object { $_.TextContent -cmatch $BasicTextFilter }
}

New-Alias -Name 'scrape' -Value Get-Site

function Get-SiteText
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AngleSharp.Html.Dom.HtmlElement[]]$Items
    )

    process
    {
        $Items | Select-Object -ExpandProperty TextContent | ForEach-Object { $_.Trim() }
    }
}

New-Alias -Name 'text' -Value Get-SiteText
