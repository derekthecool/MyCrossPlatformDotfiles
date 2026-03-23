$splat = @{
    TypeName = 'SerialPortDevice'
    Name     = 'DotFormat_SerialPortDevice'
    Property = @('device', 'description')
    AutoSize = $true
}
Write-FormatView @splat
