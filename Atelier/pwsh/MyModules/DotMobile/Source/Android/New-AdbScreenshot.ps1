function New-AdbScreenshot
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [string]$Name,

        [Parameter()]
        [string]$Serial,

        [Parameter()]
        [string]$Path = (Join-Path (Get-Location) 'screenshots' 'raw'),

        [Parameter()]
        [switch]$Frame,

        [Parameter()]
        [switch]$RemoveExisting
    )

    if (-not (Get-Command adb -ErrorAction SilentlyContinue))
    {
        throw 'adb command not found. Please install Android SDK Platform Tools.'
    }

    $framedDir = Join-Path (Split-Path $Path -Parent) 'framed'

    if ($RemoveExisting)
    {
        foreach ($dir in @($Path, $framedDir))
        {
            if (-not (Test-Path $dir)) { continue }
            $pngs = @(Get-ChildItem -Path $dir -Filter '*.png' -File -ErrorAction SilentlyContinue)
            if ($pngs.Count -eq 0) { continue }
            if ($PSCmdlet.ShouldProcess("$dir ($($pngs.Count) PNG(s))", 'Remove'))
            {
                $pngs | ForEach-Object { Remove-Item $_.FullName -Force }
                Write-Host "Cleared $($pngs.Count) PNG(s) from $dir"
            }
        }
    }

    # Single-shot if -Name provided; otherwise loop prompting until blank.
    $singleShot = -not [string]::IsNullOrWhiteSpace($Name)
    $action = if ($singleShot) { "Capture adb screenshot to $Name" } else { 'Capture adb screenshots in a loop' }
    if (-not $PSCmdlet.ShouldProcess($Path, $action)) { return }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null

    $serialArgs = if ($Serial) { @('-s', $Serial) } else { @() }
    $allResults = @()
    $captureCount = 0

    while ($true)
    {
        $currentName = if ($singleShot)
        {
            $Name
        } else
        {
            $prompted = Read-Host 'Screenshot name (blank to quit)'
            if ([string]::IsNullOrWhiteSpace($prompted)) { break }
            $prompted
        }
        if (-not $currentName.EndsWith('.png')) { $currentName += '.png' }

        $outPath = Join-Path $Path $currentName
        $basename = [IO.Path]::GetFileNameWithoutExtension($currentName)
        $devicePath = "/sdcard/DotMobile_capture_$basename.png"

        # `adb exec-out screencap -p > file.png` corrupts PNG bytes through
        # PowerShell's text-mode pipeline. Write the PNG to the device, pull it
        # via adb's binary sync protocol, then clean up.
        & adb @($serialArgs + @('shell', 'screencap', '-p', $devicePath)) *> $null
        if ($LASTEXITCODE -ne 0)
        {
            $msg = "adb shell screencap failed for device path $devicePath (exit $LASTEXITCODE)."
            if ($singleShot) { throw $msg }
            Write-Error $msg
            continue
        }

        & adb @($serialArgs + @('pull', $devicePath, $outPath)) *> $null
        if ($LASTEXITCODE -ne 0)
        {
            $msg = "adb pull failed (exit $LASTEXITCODE)."
            if ($singleShot) { throw $msg }
            Write-Error $msg
            continue
        }

        & adb @($serialArgs + @('shell', 'rm', '-f', $devicePath)) *> $null

        $result = Get-Item $outPath
        $kb = [Math]::Round($result.Length / 1KB, 1)
        Write-Host "Captured: $currentName ($kb KB) from device"
        $allResults += $result
        $captureCount++

        if ($Frame)
        {
            $framed = $result | Add-DeviceFrame -WhatIf:$WhatIfPreference
            if ($framed) { $allResults += $framed }
        }

        if ($singleShot) { break }
    }

    if ($captureCount -gt 0)
    {
        Write-Host "Captured $captureCount screenshot(s) into $Path"
    }

    return $allResults
}
