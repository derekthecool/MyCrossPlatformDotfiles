function Get-SerialPorts
{
    if($IsWindows)
    {
        Get-PnpDevice -Class ports | Where-Object { $_.Status -eq 'OK' }
    } else
    {
        # List all available serial ports (tty devices)
        $serialPorts = Get-ChildItem -Path /dev/tty* | Where-Object { $_.Name -like "tty*" }

        foreach ($port in $serialPorts)
        {
            $portName = $port.Name
            Write-Host "Serial Port: $portName"

            # Optionally, you can look at `dmesg` or `lsusb` for detailed info on the port
            $dmesg = dmesg | Select-String $portName
            Write-Host "dmesg Info: $dmesg"
        }
    }
}

New-Alias -Name ports -Value Get-SerialPorts
