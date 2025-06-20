# Uses EZOut to format as specified here
# Generate by running ../Dots.EzFormat.ps1
# Generated output located ../Dots.format.ps1xml
Write-FormatView `
    -TypeName 'System.Text.RegularExpressions.Match' `
    -Name DotsRegexView `
    -Property Value, Index, Success, Groups `
    -StyleRow {
    $_.Success ? 'Foreground.Green' : 'Foreground.Red'
} `
    -AutoSize

Write-FormatView `
    -TypeName 'Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject' `
    -Name 'DotFormat_Microsoft_PowerShell_Commands_BasicHtmlWebResponseObject' `
    -Property RawContentLength, StatusCode, StatusDescription, Content `
    -StyleRow { Format-HeatMap -InputObject $_.StatusCode -HeatMapMax 599 -HeatMapMin 100 }

# ColorProperty is not working!
#     -ColorProperty @{
#     'StatusCode' = {
#         # Format-HeatMap -InputObject $_.StatusCode -HeatMapMax 599 -HeatMapMin 100 -HeatMapCool 100 -HeatMapHot 599 -HeatMapMiddle 200
#         $_.StatusCode -le 299 ? 'Foreground.Green' : 'Foreground.Red'
#     }
# }


# -StyleRow { $_.StatusCode -le 299 ? 'Foreground.Green' : 'Foreground.Red' }
