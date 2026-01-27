function Get-SerialPorts
{
    [CmdletBinding()]
    [Alias('ports')]
    param()
    # TODO: (Derek Lomax) 1/27/2026 11:42:30 AM, split this into another module
    # TODO: (Derek Lomax) 1/27/2026 11:42:37 AM, get a better cross platform serial port checker
    if ($IsWindows)
    {
        Get-PnpDevice -Class ports | Where-Object { $_.Status -eq 'OK' }
    } else
    {
        # [System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { udevadm info -n $_ --json=short | ConvertFrom-Json } | Format-Table
        [System.IO.Ports.SerialPort]::GetPortNames()
    }
}
