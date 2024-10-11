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
