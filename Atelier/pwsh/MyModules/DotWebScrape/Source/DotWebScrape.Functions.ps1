class WebScrape
{
    [string]$Flags
    [string]$TextContent
    [string]$Attributes
    [int]$Children
    [string]$ClassName
}

function Get-Site
{

    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Url,

        [string]$QuerySelectorFilter = ""

    )

    $result = ConvertFrom-Html -Url $Url -Engine AngleSharp
    if($QuerySelectorFilter)
    {
        $result.Children[1].Children.QuerySelectorAll($QuerySelectorFilter)
    }
    else
    {
        $result.Children[1].Children
    }
}

New-Alias -Name 'scrape' -Value Get-Site
