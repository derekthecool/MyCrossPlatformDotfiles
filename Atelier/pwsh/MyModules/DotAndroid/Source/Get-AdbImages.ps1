function Get-AdbImages
{
    param (
        [Parameter()]
        [string]$DirectoryToSaveFilesTo = './'
    )

    $devices = Adb-Devices
    if ($devices -eq $null)
    {
        return
    }

    $deviceCount = (adb devices).Replace('List of devices attached', '')
    if ([string]::IsNullOrEmpty($deviceCount))
    {
        Write-Error 'No devices connected'
    }

    $DirectoryToSaveFilesTo = './'
    adb shell 'find /sdcard/DCIM/Camera/ ~/storage/*/DCIM/Camera/ -name $(date +"%Y%m%d")*'
    | ForEach-Object { $_.Replace('//', '/') -split ' ' }
    | ForEach-Object { adb pull "$_" "$DirectoryToSaveFilesTo" }
}
