<#
    .SYNOPSIS
    Adds a file name extension to a supplied name.

    .DESCRIPTION
    See more details on running plover from the command line here: https://plover.wiki/index.php/Invoke_Plover_from_the_command_line

    .PARAMETER Name
    Specifies the file name.

    .EXAMPLE
    PS> Add-Extension -name "File"
#>
function Get-PloverPath
{
    switch ($null)
    {
        { $IsWindows }
        {
            return (Get-ChildItem "$env:PROGRAMFILES/Open Steno Project/Plover*/plover_console*").FullName
        }
        { $IsLinux }
        {
            which plover
        }
        { $IsMacOS }
        {
            Get-ChildItem "/Applications/Plover.app/Contents/MacOS/Plover"
        }
        default
        {
            throw 'System not supported'
        }
    }
}

function Invoke-Plover
{
    $ploverPath = Get-PloverPath
    if (-not $ploverPath)
    {
        throw 'Could not find plover_console'
    }

    Push-Location .
    $command = "& '$ploverPath' $args"
    Set-Location (Split-Path (Get-PloverPath))
    Write-Host "Running plover command: $command" -ForegroundColor Green
    Invoke-Expression $command
    Pop-Location
}

Set-Alias -Name plover -Value Invoke-Plover -Force
Set-Alias -Name plover_console -Value Invoke-Plover -Force

function Install-PloverPlugin
{
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [string[]]$Plugins
    )

    process
    {
        foreach ($plugin in $Plugins)
        {
            Write-Host "Installing plover plugin $_"
            Invoke-Plover -s plover_plugins install $plugin
            Start-Sleep 5
        }
    }
}

function Install-PloverSavedPlugins
{
    $plugins = @(
        "plover-markdown-dictionary"
        "spectra-lexer"
        "plover-emoji"
        "plover-fancytext"
        "plover-python-dictionary"
        "plover-tapey-tape"
        "plover-current-time"
        "plover-delay"
        "pyperclip"
    )

    $plugins | Install-PloverPlugin
}

function Get-PloverConfigurationDirectory
{
    switch ($null)
    {
        { $IsWindows }
        {
            "$env:LOCALAPPDATA/Plover/Plover"
        }
        { $IsLinux }
        {
            "$HOME/.config/plover"
        }
        { $IsMacOS }
        {
            "$HOME/Library/Application Support/plover"
        }
        default
        {
            throw 'unknown plover system'
        }
    }
}

function Get-TapeyTapePath
{
    "$(Get-PloverConfigurationDirectory)/tapey_tape.txt"
}

function Get-PloverLatestRelease
{
    <#
    .SYNOPSIS
    Checks for the latest Plover release from GitHub.

    .DESCRIPTION
    Fetches the latest Plover release from GitHub and compares it with the
    currently installed version (if any). Returns information about update
    availability.

    .EXAMPLE
    Get-PloverLatestRelease

    .EXAMPLE
    $release = Get-PloverLatestRelease
    if ($release.UpdateAvailable) {
        Write-Host "New version available: $($release.LatestVersion)"
    }
    #>
    # Use Get-LatestGithubRelease from DotGit module
    $release = Get-LatestGithubRelease -Repo 'opensteno/plover'

    # Get current installed version
    $installedVersion = $null
    try
    {
        $ploverExe = Get-PloverPath
        $versionOutput = & $ploverExe --version 2>&1 | Out-String
        # Parse version string (format varies: "Plover 5.3.0", "Plover version 5.3.0", etc.)
        if ($versionOutput -match '(\d+\.\d+\.\d+)')
        {
            $installedVersion = $matches[1]
        }
    } catch
    {
        # Plover not installed, leave $installedVersion as $null
    }

    # Compare versions (strip "v" prefix from GitHub tag)
    $latestVersionClean = $release.TagName -replace '^v', ''
    $updateAvailable = if ($installedVersion)
    {
        $latestVersionClean -ne $installedVersion
    } else
    {
        $true  # Not installed, so update is available
    }

    # Return result object
    [PSCustomObject]@{
        LatestVersion    = $release.TagName
        InstalledVersion = $installedVersion
        UpdateAvailable  = $updateAvailable
        LatestReleaseUrl = $release.HtmlUrl
        ReleaseNotes     = $release.Body
        PublishedAt      = $release.PublishedAt
        Assets           = $release.Assets  # Full asset list for reference
    }
}

function Install-PloverLatestRelease
{
    <#
    .SYNOPSIS
    Downloads and installs the latest Plover release.

    .DESCRIPTION
    Downloads the latest Plover release from GitHub and installs it based on
    the current platform. Supports Linux (AppImage), Windows (installer), and macOS (DMG).

    .PARAMETER Force
    Overwrite existing installation without prompting.

    .EXAMPLE
    Install-PloverLatestRelease

    .EXAMPLE
    Install-PloverLatestRelease -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Force
    )

    # Use Get-LatestGithubRelease from DotGit module
    $release = Get-LatestGithubRelease -Repo 'opensteno/plover'

    # Filter assets based on platform
    $assetUrl = $null
    $destinationPath = $null

    switch ($null)
    {
        { $IsLinux }
        {
            # Find AppImage asset
            $asset = $release.Assets | Where-Object { $_.Name -match '-x86_64\.AppImage$' } | Select-Object -First 1
            if (-not $asset)
            {
                throw 'No AppImage found in latest release assets'
            }
            $assetUrl = $asset.BrowserDownloadUrl
            $destinationPath = Join-Path $HOME '.local/bin/plover.AppImage'

            # Ensure directory exists
            $destinationDir = Split-Path $destinationPath -Parent
            if (-not (Test-Path $destinationDir))
            {
                New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }
        }
        { $IsWindows }
        {
            # Find Windows installer asset (non-portable)
            $asset = $release.Assets | Where-Object { $_.Name -match '-win64\.setup\.exe$' } | Select-Object -First 1
            if (-not $asset)
            {
                throw 'No Windows installer found in latest release assets'
            }
            $assetUrl = $asset.BrowserDownloadUrl
            $destinationPath = Join-Path $env:TEMP 'plover-setup.exe'
        }
        { $IsMacOS }
        {
            # Find macOS DMG asset
            $asset = $release.Assets | Where-Object { $_.Name -match '-macosx_.*_universal2\.dmg$' } | Select-Object -First 1
            if (-not $asset)
            {
                throw 'No macOS DMG found in latest release assets'
            }
            $assetUrl = $asset.BrowserDownloadUrl
            $destinationPath = Join-Path $env:TEMP 'Plover.dmg'
        }
        default
        {
            throw "Unsupported platform for Plover installation"
        }
    }

    # Check if file already exists
    if ((Test-Path $destinationPath) -and -not $Force)
    {
        Write-Warning "Plover already exists at: $destinationPath"
        $confirm = Read-Host "Do you want to overwrite? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y')
        {
            Write-Host 'Installation cancelled.'
            return
        }
    }

    # Download
    Write-Host "Downloading Plover from: $assetUrl" -ForegroundColor Cyan
    Write-Host "Destination: $destinationPath" -ForegroundColor Cyan

    if ($PSCmdlet.ShouldProcess($destinationPath, 'Download Plover'))
    {
        try
        {
            Invoke-WebRequest -Uri $assetUrl -OutFile $destinationPath -UseBasicParsing
            Write-Host 'Download completed successfully.' -ForegroundColor Green
        } catch
        {
            throw "Failed to download Plover: $_"
        }

        # Verify download
        if (-not (Test-Path $destinationPath))
        {
            throw 'Download failed - file not found'
        }

        $fileSize = (Get-Item $destinationPath).Length
        if ($fileSize -lt 1MB)
        {
            throw "Download may have failed - file size is only $fileSize bytes"
        }

        # Platform-specific post-download setup
        switch ($null)
        {
            { $IsLinux }
            {
                # Make AppImage executable
                Write-Host 'Making AppImage executable...' -ForegroundColor Cyan
                bash -c "chmod +x '$destinationPath'"
                Write-Host "Plover AppImage installed to: $destinationPath" -ForegroundColor Green
                Write-Host 'Run Plover with: plover or ~/.local/bin/plover.AppImage' -ForegroundColor Yellow
            }
            { $IsWindows }
            {
                # Run installer
                Write-Host 'Launching installer...' -ForegroundColor Cyan
                Write-Host 'Please follow the installer prompts to complete installation.' -ForegroundColor Yellow
                Start-Process -FilePath $destinationPath -Wait
                Write-Host 'Installation completed.' -ForegroundColor Green
                Write-Host 'You can now launch Plover from the Start Menu.' -ForegroundColor Yellow
            }
            { $IsMacOS }
            {
                # Mount DMG and copy to /Applications
                Write-Host 'Installing Plover to /Applications...' -ForegroundColor Cyan

                # Mount DMG
                $mountResult = bash -c "hdiutil attach '$destinationPath' -readonly" 2>&1
                if ($LASTEXITCODE -ne 0)
                {
                    throw "Failed to mount DMG: $mountResult"
                }

                try
                {
                    # Copy app to /Applications
                    $appPath = '/Volumes/Plover/Plover.app'
                    if (-not (Test-Path $appPath))
                    {
                        throw "Plover.app not found in DMG"
                    }

                    bash -c "cp -R '$appPath' /Applications/"

                    Write-Host 'Plover installed to /Applications.' -ForegroundColor Green
                    Write-Host 'You can now launch Plover from Finder or Spotlight.' -ForegroundColor Yellow
                } finally
                {
                    # Unmount DMG
                    bash -c "hdiutil detach '/Volumes/Plover' 2>/dev/null"
                }
            }
        }
    }
}
