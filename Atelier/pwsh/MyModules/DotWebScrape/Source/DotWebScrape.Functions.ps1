<#
    .SYNOPSIS
    Web scraping in powershell made easy

    .DESCRIPTION
    This function uses the module https://github.com/EvotecIT/PSParseHTML which itself includes two
    dotnet packages AngleSharp and HtmlAgilityPack

    .PARAMETER Url
    Link to site to scrape

    .PARAMETER QuerySelectorFilter
    CSS query selector to filter, defaults to using * which will show all children recursively

    .EXAMPLE
    PS> Add-Extension -name "File"
#>
function Get-Site
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Url,

        # Default to using * for the query filter to select everything recursively
        [string]$QuerySelectorFilter = "*"
    )

    $result = ConvertFrom-Html -Url $Url -Engine AngleSharp
    $result.Children[1].Children.QuerySelectorAll($QuerySelectorFilter)
}

New-Alias -Name 'scrape' -Value Get-Site
