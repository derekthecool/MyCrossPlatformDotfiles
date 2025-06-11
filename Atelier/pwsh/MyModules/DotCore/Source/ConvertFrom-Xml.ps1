<#
    .SYNOPSIS
    The missing/forgotten data conversion tool absent in pwsh 7.5+

    .DESCRIPTION
    Works like ConvertFrom-Json

    .PARAMETER XmlContent
    XmlContent is either of type [xml] or [string]

    .PARAMETER XPath
    Optional xml XPath parser

    .EXAMPLE
    # Parse sample xml from Microsoft website: https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ms762271(v=vs.85)
    $xml = @"
<?xml version="1.0"?> <catalog> <book id="bk101"> <author>Gambardella, Matthew</author> <title>XML Developer's Guide</title> <genre>Computer</genre> <price>44.95</price> <publish_date>2000-10-01</publish_date> <description>An in-depth look at creating applications with XML.</description> </book> <book id="bk102"> <author>Ralls, Kim</author> <title>Midnight Rain</title> <genre>Fantasy</genre> <price>5.95</price> <publish_date>2000-12-16</publish_date> <description>A former architect battles corporate zombies, an evil sorceress, and her own childhood to become queen of the world.</description> </book> <book id="bk103"> <author>Corets, Eva</author> <title>Maeve Ascendant</title> <genre>Fantasy</genre> <price>5.95</price> <publish_date>2000-11-17</publish_date> <description>After the collapse of a nanotechnology society in England, the young survivors lay the foundation for a new society.</description> </book> <book id="bk104"> <author>Corets, Eva</author> <title>Oberon's Legacy</title> <genre>Fantasy</genre> <price>5.95</price> <publish_date>2001-03-10</publish_date> <description>In post-apocalypse England, the mysterious agent known only as Oberon helps to create a new life for the inhabitants of London. Sequel to Maeve Ascendant.</description> </book> <book id="bk105"> <author>Corets, Eva</author> <title>The Sundered Grail</title> <genre>Fantasy</genre> <price>5.95</price> <publish_date>2001-09-10</publish_date> <description>The two daughters of Maeve, half-sisters, battle one another for control of England. Sequel to Oberon's Legacy.</description> </book> <book id="bk106"> <author>Randall, Cynthia</author> <title>Lover Birds</title> <genre>Romance</genre> <price>4.95</price> <publish_date>2000-09-02</publish_date> <description>When Carla meets Paul at an ornithology conference, tempers fly as feathers get ruffled.</description> </book> <book id="bk107"> <author>Thurman, Paula</author> <title>Splish Splash</title> <genre>Romance</genre> <price>4.95</price> <publish_date>2000-11-02</publish_date> <description>A deep sea diver finds true love twenty thousand leagues beneath the sea.</description> </book> <book id="bk108"> <author>Knorr, Stefan</author> <title>Creepy Crawlies</title> <genre>Horror</genre> <price>4.95</price> <publish_date>2000-12-06</publish_date> <description>An anthology of horror stories about roaches, centipedes, scorpions  and other insects.</description> </book> <book id="bk109"> <author>Kress, Peter</author> <title>Paradox Lost</title> <genre>Science Fiction</genre> <price>6.95</price> <publish_date>2000-11-02</publish_date> <description>After an inadvertant trip through a Heisenberg Uncertainty Device, James Salway discovers the problems of being quantum.</description> </book> <book id="bk110"> <author>O'Brien, Tim</author> <title>Microsoft .NET: The Programming Bible</title> <genre>Computer</genre> <price>36.95</price> <publish_date>2000-12-09</publish_date> <description>Microsoft's .NET initiative is explored in detail in this deep programmer's reference.</description> </book> <book id="bk111"> <author>O'Brien, Tim</author> <title>MSXML3: A Comprehensive Guide</title> <genre>Computer</genre> <price>36.95</price> <publish_date>2000-12-01</publish_date> <description>The Microsoft MSXML3 parser is covered in detail, with attention to XML DOM interfaces, XSLT processing, SAX and more.</description> </book> <book id="bk112"> <author>Galos, Mike</author> <title>Visual Studio 7: A Comprehensive Guide</title> <genre>Computer</genre> <price>49.95</price> <publish_date>2001-04-16</publish_date> <description>Microsoft Visual Studio 7 is explored in depth, looking at how Visual Basic, Visual C++, C#, and ASP+ are integrated into a comprehensive development environment.</description> </book> </catalog>
"@
    # Without XPath
    $xml | ConvertFrom-Xml

    # With XPath
    $xml | ConvertFrom-Xml -XPath '//publish_date'
#>
function ConvertFrom-Xml
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [Alias('Xml')]
        [object]$XmlContent,

        [string]$XPath
    )

    begin
    {
        function Remove-XmlNamespacesAndPrefixes
        {
            param([string]$xml)

            $xmlDecl = ''
            if ($xml -match '^(<\?xml.*?\?>)')
            {
                $xmlDecl = $matches[1]
                $xml = $xml -replace '^(<\?xml.*?\?>)', ''
            }

            $xml = [regex]::Replace($xml, '\sxmlns(:\w+)?="[^"]+"', '')
            $xml = [regex]::Replace($xml, '(</?)(\w+:)', '$1')
            $xml = [regex]::Replace($xml, '(\s)\w+:(\w+=)', '$1$2')

            return "$xmlDecl$xml"
        }

        function Convert-XmlNode
        {
            param($node)

            if ($null -eq $node)
            { return $null
            }

            if ($node -is [System.Xml.XmlText] -or $node -is [System.Xml.XmlCDataSection])
            {
                return $node.Value
            }

            if ($node -is [System.Xml.XmlElement])
            {
                # If it only has a text child, return its inner text
                if ($node.HasChildNodes -and $node.ChildNodes.Count -eq 1 -and $node.FirstChild.NodeType -eq 'Text')
                {
                    return $node.InnerText
                }

                # Process children normally
                $result = @{}
                foreach ($child in $node.ChildNodes)
                {
                    $childName = $child.Name
                    $convertedChild = Convert-XmlNode $child

                    if ($result.ContainsKey($childName))
                    {
                        if ($result[$childName] -isnot [System.Collections.IEnumerable] -or $result[$childName] -is [string])
                        {
                            $result[$childName] = @($result[$childName])
                        }
                        $result[$childName] += $convertedChild
                    } else
                    {
                        $result[$childName] = $convertedChild
                    }
                }

                return [pscustomobject]$result
            }

            return $node.InnerText
        }
    }

    process
    {
        $xmlString =
        if ($XmlContent -is [xml])
        {
            $XmlContent.OuterXml
        } elseif ($XmlContent -is [string])
        {
            $XmlContent
        } else
        {
            throw "Unsupported input type: $($XmlContent.GetType().Name)"
        }

        $cleanXmlString = Remove-XmlNamespacesAndPrefixes -xml $xmlString

        try
        {
            [xml]$xmlObj = $cleanXmlString
        } catch
        {
            throw "Invalid XML after cleaning: $_"
        }

        $nodes = if ($XPath)
        {
            $xmlObj.SelectNodes($XPath)
        } else
        {
            @($xmlObj.DocumentElement)
        }

        foreach ($node in $nodes)
        {
            Convert-XmlNode $node
        }
    }
}
