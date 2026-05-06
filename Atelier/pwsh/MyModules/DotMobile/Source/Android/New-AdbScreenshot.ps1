function New-AdbScreenshot
{
    param (
        [Parameter()]
        [string]$OutputPathNameWithoutFileEnding
    )

    # Check if adb command is available
    if (-not (Get-Command adb -ErrorAction SilentlyContinue))
    {
        throw 'adb command not found. Please install Android SDK Platform Tools.'
    }

    adb exec-out screencap -p > "$OutputPathNameWithoutFileEnding.png"
}
