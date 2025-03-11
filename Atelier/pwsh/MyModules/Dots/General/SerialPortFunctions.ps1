function Get-SerialPorts
{
    if ($IsWindows)
    {
        Get-PnpDevice -Class ports | Where-Object { $_.Status -eq 'OK' }
    } else
    {
        [System.IO.Ports.SerialPort]::GetPortNames()
    }
}

New-Alias -Name ports -Value Get-SerialPorts
