function Get-AdbLogCode
{
    $file = "sdcard/logs/m"
    Write-Host "Waiting for adb device" -ForegroundColor Green
    adb wait-for-device
    Write-Host "Device connected" -ForegroundColor Green
    $code_file = adb shell cat $file

    if ([string]::IsNullOrEmpty($code_file))
    {
        Write-Error "file $file is empty"
        return
    }

    $code_match = ([regex]'(\d+)').Match($($code_file))
    if ($code_match.Success)
    {
        Write-Host "Code found"
        Set-Clipboard $code_match.Value
        $code_match.Value
    } else
    {
        Write-Error "Code not found"
    }
}
