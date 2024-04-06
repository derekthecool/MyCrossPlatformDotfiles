enum AdbState {
    Normal
    Unauthorized
    Offline
}

class AdbDevice {
    [string]$Id
    [AdbState]$State

    AdbDevice([string]$Id, [AdbState]$State) {
        $this.Id = $Id
        $this.State = $State
    }
}

function Adb-Devices {
    try {
        # Attempt to run `adb get-state` to see if adb is accessible
        $adbStateOutput = adb get-state 2>&1
        if($adbStateOutput -match 'error: no devices/emulators found') {
            Write-Error 'No devices found'
            return $false
        }

        $deviceLines = $(adb devices) -split '\r?\n' | Where-Object { $_ -match '\w+' } | Select-Object -Skip 1

        $devices = $deviceLines | ForEach-Object {
            $splitOutput = $_ -split '\s+'
            $state = switch ($splitOutput[1]) {
                'device' {
                    [AdbState]::Normal
                }
                'unauthorized' {
                    [AdbState]::Unauthorized
                }
                'offline' {
                    [AdbState]::Offline
                }
                Default {
                    [AdbState]::Offline
                } # Fallback case if state is not recognized
            }

            [AdbDevice]::new($splitOutput[0], $state)
        }

        return $devices
    } catch {
        Write-Error "adb command failed: $_"
        return $false
    }
}

function Get-AdbImages {
    param (
        [Parameter()]
        [string]$DirectoryToSaveFilesTo = './'
    )

    $devices = Adb-Devices
    if($devices -eq $null) {
        return
    }


    $deviceCount = (adb devices).Replace('List of devices attached','')
    if([string]::IsNullOrEmpty($deviceCount)) {
        Write-Error 'No devices connected'
    }

    $DirectoryToSaveFilesTo = './'
    adb shell 'find /sdcard/DCIM/Camera/ ~/storage/*/DCIM/Camera/ -name $(date +"%Y%m%d")*.jpg'
    | ForEach-Object { $_.Replace('//','/') -split ' ' }
    | ForEach-Object { adb pull "$_" "$DirectoryToSaveFilesTo" }
}
