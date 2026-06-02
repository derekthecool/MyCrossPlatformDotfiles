
$splat = @{
    TypeName = 'Kroger.Location'
    Name     = 'Kroger_Location'
    Property = @('LocationId', 'Chain', 'Name')
    AutoSize = $true
}
Write-FormatView @splat
