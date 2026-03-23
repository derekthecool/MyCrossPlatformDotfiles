Write-FormatView `
    -TypeName 'System.Text.RegularExpressions.Match' `
    -Name DotsRegexView `
    -Property Value, Index, Success, Groups `
    -StyleRow {
    $_.Success ? 'Foreground.Green' : 'Foreground.Red'
} `
    -AutoSize

Write-FormatListView -ViewTypeName 'DotInvokeRestForceList' -Property A, B, C
