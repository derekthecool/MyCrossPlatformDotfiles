# Uses EZOut to format as specified here
# Generate by running ../Dots.EzFormat.ps1
# Generated output located ../Dots.format.ps1xml

# List format view
Write-FormatView `
    -TypeName 'System.Management.Automation.AliasInfo' `
    -Name DotsAliasInfoView `
    -Property Name, Definition, CommandType `
    -AutoSize `
    -StyleRow {
    'Foreground.Green'
}

# Pretty much the same as aliases but for executables instead
Write-FormatView `
    -TypeName 'System.Management.Automation.ApplicationInfo' `
    -Name DotsApplicationInfoView `
    -Property Name, Definition, CommandType `
    -AutoSize `
    -StyleRow {
    'Foreground.Yellow'
}
