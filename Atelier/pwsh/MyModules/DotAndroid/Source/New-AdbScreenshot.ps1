function New-AdbScreenshot
{
    param (
        [Parameter()]
        [string]$OutputPathNameWithoutFileEnding
    )

    adb exec-out screencap -p > "$OutputPathNameWithoutFileEnding.png"
}
