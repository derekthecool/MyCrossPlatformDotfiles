# Uses EZOut to format as specified here
# Generate by running ../Dots.EzFormat.ps1
# Generated output located ../Dots.format.ps1xml
Write-FormatView `
    -TypeName 'AngleSharp.Html.Dom.HtmlHtmlElement' `
    -Name AngleSharp_Html_Dom_HtmlHtmlElement `
    -Property Items, NamespaceUri, Language `
    -VirtualProperty @{
    Items = { $_.Children[1].ChildElementCount }
} -AutoSize

$splat = @{
    TypeName = 'AngleSharp.Html.Dom.HtmlElement'
    Name = 'HtmlElement'
    Property = @('TagName', 'ChildElementCount', 'Html', 'TextContent')
    VirtualProperty = @{
        Html = { $_.OuterHtml -replace '\s+', ' ' }
    }
    AutoSize = $true
}
Write-FormatView @splat
