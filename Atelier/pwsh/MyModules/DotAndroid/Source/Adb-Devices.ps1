<#
https://gist.github.com/Pulimet/5013acf2cd5b28e55036c82c91bd56d8#file-adbcommands
#>

enum AdbState
{
    Normal
    Unauthorized
    Offline
}

class AdbDevice
{
    [string]$Id
    [AdbState]$State

    AdbDevice([string]$Id, [AdbState]$State)
    {
        $this.Id = $Id
        $this.State = $State
    }
}

function Get-AdbDevices
{
    try
    {
        # Attempt to run `adb get-state` to see if adb is accessible
        $adbStateOutput = adb get-state 2>&1
        if ($adbStateOutput -match 'error: no devices/emulators found')
        {
            Write-Error 'No devices found'
            return $false
        }

        $deviceLines = $(adb devices) -split '\r?\n' | Where-Object { $_ -match '\w+' } | Select-Object -Skip 1

        $devices = $deviceLines | ForEach-Object {
            $splitOutput = $_ -split '\s+'
            $state = switch ($splitOutput[1])
            {
                'device'
                {
                    [AdbState]::Normal
                }
                'unauthorized'
                {
                    [AdbState]::Unauthorized
                }
                'offline'
                {
                    [AdbState]::Offline
                }
                Default
                {
                    [AdbState]::Offline
                } # Fallback case if state is not recognized
            }

            [AdbDevice]::new($splitOutput[0], $state)
        }

        return $devices
    } catch
    {
        Write-Error "adb command failed: $_"
        return $false
    }
}
