# Uses EZOut to format as specified here
# Generate by running ../Dots.EzFormat.ps1
# Generated output located ../Dots.format.ps1xml
Write-FormatView `
    -TypeName 'Microsoft.Management.Infrastructure.CimInstance#ROOT/cimv2/Win32_PnPEntity' `
    -Name DotsPNPDevice `
    -Property Name, Port, DeviceId, Status `
    -VirtualProperty @{
        Port = { [Regex]::Match($_.Name, '(COM\d+)').Value }
    } -StyleRow {
    $_.Status -eq 'OK' ? 'Foreground.Green' : 'Foreground.Red'
} `
    -AutoSize
