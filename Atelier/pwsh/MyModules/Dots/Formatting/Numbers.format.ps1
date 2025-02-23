# Uses EZOut to format as specified here
# Generate by running ../Dots.EzFormat.ps1
# Generated output located ../Dots.format.ps1xml
Write-FormatView `
    -TypeName 'System.Int32' `
    -Name DotsInt32View `
    -Property Hex `
    -VirtualProperty @{
    Hex = {
        "{0:X}" -f $_
    }
    Dec = {
        $_
    }
}
