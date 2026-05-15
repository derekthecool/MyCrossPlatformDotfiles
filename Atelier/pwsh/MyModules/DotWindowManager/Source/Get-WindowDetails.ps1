function Get-WindowDetails
{
    <#
    .SYNOPSIS
    Gets window details by inspecting a clicked window.

    .DESCRIPTION
    Prompts the user to click a window, then uses platform-specific tools to get window details.
    On Linux: Uses xprop to get WM_CLASS, WM_NAME, and WM_WINDOW_ROLE.
    On Windows: Opens AutoHotkey Window Spy (GUI) for manual inspection.
    On Mac: TODO - No easy CLI method yet.

    .EXAMPLE
    Get-WindowDetails
    # Prompts to click window and displays details

    .EXAMPLE
    Get-WindowDetails | Add-WMRoute -Workspace 2
    # Gets window details and adds as route to workspace 2

    .EXAMPLE
    Get-WindowDetails | Add-WMFilter
    # Gets window details and adds as filter
    #>

    [CmdletBinding()]
    param()

    Write-Host "=== Get Window Details ===" -ForegroundColor Cyan
    Write-Host ""

    if ($IsLinux)
    {
        Write-Host "Platform: Linux (using xprop)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "INSTRUCTIONS:" -ForegroundColor White
        Write-Host "  Click on any window to get its details..." -ForegroundColor Gray
        Write-Host ""

        # Use xprop to select window and get properties
        $xpropOutput = & xprop 2>&1

        if ($LASTEXITCODE -ne 0 -or -not $xpropOutput)
        {
            Write-Host "Error: Failed to get window details. Make sure xprop is installed." -ForegroundColor Red
            Write-Host "Install with: sudo apt install x11-utils xdotool" -ForegroundColor Yellow
            return
        }

        # Parse xprop output
        $details = [PSCustomObject]@{
            Name     = $null
            Class    = $null
            Instance = $null
            Role     = $null
        }

        foreach ($line in $xpropOutput)
        {
            if ($line -match 'WM_NAME\(STRING\) = "(.*)"')
            {
                $details.Name = $matches[1]
            }
            if ($line -match 'WM_CLASS\(STRING\) = "(.*)", "(.*)"')
            {
                $details.Instance = $matches[1]
                $details.Class = $matches[2]
            }
            if ($line -match 'WM_WINDOW_ROLE\(STRING\) = "(.*)"')
            {
                $details.Role = $matches[1]
            }
        }

        # Display results
        Write-Host "=== Window Details ===" -ForegroundColor Cyan
        Write-Host "Name:     " -NoNewline; Write-Host $details.Name -ForegroundColor White
        Write-Host "Class:    " -NoNewline; Write-Host $details.Class -ForegroundColor White
        Write-Host "Instance: " -NoNewline; Write-Host $details.Instance -ForegroundColor White
        Write-Host "Role:     " -NoNewline; Write-Host $details.Role -ForegroundColor White
        Write-Host ""

        # Output as custom object with Add-WMRoute/Add-WMFilter compatible format
        $results = [System.Collections.ArrayList]::new()

        if ($details.Class)
        {
            $results.Add([PSCustomObject]@{
                    Name   = $details.Class
                    Type   = "class"
                    Source = "WM_CLASS"
                }) | Out-Null
        }

        if ($details.Instance)
        {
            $results.Add([PSCustomObject]@{
                    Name   = $details.Instance
                    Type   = "instance"
                    Source = "WM_CLASS instance"
                }) | Out-Null
        }

        if ($details.Role)
        {
            $results.Add([PSCustomObject]@{
                    Name   = $details.Role
                    Type   = "role"
                    Source = "WM_WINDOW_ROLE"
                }) | Out-Null
        }

        return $results

    } elseif ($IsWindows)
    {
        Write-Host "Platform: Windows (using AutoHotkey Window Spy)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "INSTRUCTIONS:" -ForegroundColor White
        Write-Host "  1. AutoHotkey Window Spy will open" -ForegroundColor Gray
        Write-Host "  2. Click on the window you want to inspect" -ForegroundColor Gray
        Write-Host "  3. Copy the relevant details:" -ForegroundColor Gray
        Write-Host "     - ahk_class  → Class" -ForegroundColor Gray
        Write-Host "     - ahk_exe    → Process" -ForegroundColor Gray
        Write-Host "     - ahk_title  → Title" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Press Enter to open AutoHotkey Window Spy..." -ForegroundColor Yellow
        $null = Read-Host

        # Try to find and launch AutoHotkey Window Spy
        $ahkPaths = @(
            "${env:ProgramFiles}\AutoHotkey\WindowSpy.ahk",
            "${env:ProgramFiles(x86)}\AutoHotkey\WindowSpy.ahk",
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\WindowSpy.ahk"
        )

        $windowSpy = $ahkPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($windowSpy)
        {
            Start-Process "autohotkey.exe" -ArgumentList $windowSpy
        } else
        {
            Write-Host "Error: AutoHotkey Window Spy not found." -ForegroundColor Red
            Write-Host "Please install AutoHotkey from: https://www.autohotkey.com/" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "TODO: Add CLI window scraper support (like xprop for Linux)" -ForegroundColor Yellow
            return
        }

        Write-Host ""
        Write-Host "Window Spy is now running. Use it to inspect windows." -ForegroundColor Green
        Write-Host "Manually add routes using the values shown in Window Spy." -ForegroundColor Gray
        return

    } else
    {
        Write-Host "Platform: macOS" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "TODO: No easy CLI method for macOS window inspection yet." -ForegroundColor Red
        Write-Host "Possible options to investigate:" -ForegroundColor Yellow
        Write-Host "  - AppleScript (requires accessibility permissions)" -ForegroundColor Gray
        Write-Host "  - CGWindowListCopyWindowInfo (C API)" -ForegroundColor Gray
        Write-Host "  - Third-party tools like 'osascript'" -ForegroundColor Gray
        return
    }
}
