<#
    .SYNOPSIS
    Get serial ports

    .DESCRIPTION
    Get all serial ports and detailed HID information

    .EXAMPLE
    Get-SerialPort

Interestingly a python solution might work best:
pip install pyserial

import serial.tools.list_ports
for port in serial.tools.list_ports.comports():
    print(port.device, port.description)

# Windows output:
COM21 Standard Serial over Bluetooth link (COM21)
COM23 Standard Serial over Bluetooth link (COM23)
COM3 Intel(R) Active Management Technology - SOL (COM3)
COM24 Standard Serial over Bluetooth link (COM24)
COM4 USB Serial Device (COM4)
COM10 Silicon Labs CP210x USB to UART Bridge (COM10)
COM22 Standard Serial over Bluetooth link (COM22)

# Linux output:
/dev/ttyUSB0 TTL232R - TTL232R
#>
function Get-SerialPort
{
    [CmdletBinding()]
    [Alias('ports')]
    param()
    # TODO: (Derek Lomax) 1/27/2026 11:42:30 AM, split this into another module
    if (-not $(Get-Command python -ErrorAction SilentlyContinue))
    {
        throw "The command [python] not found cannot continue program"
    }
    if (-not $(Get-Command pip -ErrorAction SilentlyContinue))
    {
        throw "The command [pip] not found cannot continue program"
    }
    
    $command = @'
import json
import serial.tools.list_ports
print(json.dumps(list(map(lambda x: vars(x),serial.tools.list_ports.comports()))))
'@
    $result = & python -c $command
    if (-not $? -or $LASTEXITCODE -ne 0)
    {
        if ($result -match 'ModuleNotFoundError')
        {
            throw "pyserial module not found, run pip install pyserial"
        }
        Write-Error "Python command failed: $result"
        throw "Unexpected python error result"
    }

    $result | ConvertFrom-Json | ForEach-Object {
        $device = $_
        $device | Add-Member -TypeName SerialPortDevice
        try
        {
            Write-Verbose "Checking to see if $($device.name) serial port can be opened"
            $port = [IO.Ports.SerialPort]::new($device.name)
            $port.Open()
            $port.Close()
            $canOpen = $true
        } catch
        {
            $canOpen = $false
        }
        $device | Add-Member -NotePropertyName Available -NotePropertyValue $canOpen
        $device
    }
}
