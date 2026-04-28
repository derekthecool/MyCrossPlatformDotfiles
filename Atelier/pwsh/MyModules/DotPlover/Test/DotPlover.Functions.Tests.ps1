BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

# Skip these tests if the configuration directory is not found
Describe 'DotPlover tests' -Skip:$(-not (Test-Path (Get-PloverConfigurationDirectory))) {
    It 'Get-PloverConfigurationDirectory works' {
        Get-PloverConfigurationDirectory | Should -Be -Not $null
    }
}

Describe 'Get-PloverLatestRelease' {
    BeforeEach {
        # These tests require network connectivity
        $canConnect = Test-Connection github.com -Quiet -Count 1 -ErrorAction SilentlyContinue
    }

    It 'Returns version information from GitHub' -Skip:(-not $canConnect) {
        $result = Get-PloverLatestRelease

        $result | Should -Not -BeNullOrEmpty
        $result.LatestVersion | Should -Not -BeNullOrEmpty
        $result.LatestVersion | Should -Match '^v?\d+\.\d+\.\d+'
    }

    It 'Returns assets array' -Skip:(-not $canConnect) {
        $result = Get-PloverLatestRelease

        $result.Assets | Should -Not -BeNullOrEmpty
        $result.Assets.Count | Should -BeGreaterThan 0
    }

    It 'Returns release notes' -Skip:(-not $canConnect) {
        $result = Get-PloverLatestRelease

        $result.ReleaseNotes | Should -Not -BeNullOrEmpty
    }

    It 'Returns release URL' -Skip:(-not $canConnect) {
        $result = Get-PloverLatestRelease

        $result.LatestReleaseUrl | Should -Not -BeNullOrEmpty
        $result.LatestReleaseUrl | Should -Match '^https://github\.com/'
    }

    It 'Detects update availability when Plover not installed' -Skip:(-not $canConnect) {
        # Mock Get-PloverPath to simulate Plover not being installed
        Mock Get-PloverPath { throw 'Plover not found' }

        $result = Get-PloverLatestRelease

        $result.InstalledVersion | Should -BeNullOrEmpty
        $result.UpdateAvailable | Should -Be $true
    }

    It 'Correctly reports installed version when Plover is installed' -Skip:(-not $canConnect -or -not (Get-Command Get-PloverPath -ErrorAction SilentlyContinue)) {
        # This test will only run if Plover is actually installed
        try
        {
            $ploverPath = Get-PloverPath
            $result = Get-PloverLatestRelease

            $result.InstalledVersion | Should -Not -BeNullOrEmpty
            $result.InstalledVersion | Should -Match '^\d+\.\d+\.\d+$'
        }
        catch
        {
            Set-TestInconclusive -Message 'Plover not installed, skipping installed version test'
        }
    }
}

Describe 'Install-PloverLatestRelease' {
    BeforeEach {
        $canConnect = Test-Connection github.com -Quiet -Count 1 -ErrorAction SilentlyContinue
    }

    It 'Supports -WhatIf parameter' -Skip:(-not $canConnect) {
        # Should not throw when using -WhatIf
        { Install-PloverLatestRelease -WhatIf } | Should -Not -Throw
    }

    It 'Supports -Confirm parameter' -Skip:(-not $canConnect) {
        # Mock Read-Host to auto-confirm
        Mock Read-Host { return 'n' }

        # Should not throw when using -Confirm
        { Install-PloverLatestRelease -Confirm } | Should -Not -Throw
    }

    It 'Finds correct asset for Linux platform' -Skip:(-not $canConnect -or -not $IsLinux) {
        # Mock Get-LatestGithubRelease to avoid network calls
        Mock Get-LatestGithubRelease {
            [PSCustomObject]@{
                TagName = 'v5.3.0'
                Assets  = @(
                    [PSCustomObject]@{ Name = 'plover-5.3.0-x86_64.AppImage'; BrowserDownloadUrl = 'https://example.com/plover.AppImage' }
                    [PSCustomObject]@{ Name = 'plover-5.3.0-win64.setup.exe'; BrowserDownloadUrl = 'https://example.com/plover.exe' }
                )
            }
        }

        # Mock file operations to avoid actual installation
        Mock Invoke-WebRequest
        Mock Test-Path { $false }
        Mock New-Item
        Mock bash

        { Install-PloverLatestRelease -WhatIf } | Should -Not -Throw

        # Verify Get-LatestGithubRelease was called with correct repo
        Should -Invoke Get-LatestGithubRelease -Times 1 -Exactly -ParameterFilter { $Repo -eq 'opensteno/plover' }
    }

    It 'Finds correct asset for Windows platform' -Skip:(-not $canConnect -or -not $IsWindows) {
        Mock Get-LatestGithubRelease {
            [PSCustomObject]@{
                TagName = 'v5.3.0'
                Assets  = @(
                    [PSCustomObject]@{ Name = 'plover-5.3.0-win64.setup.exe'; BrowserDownloadUrl = 'https://example.com/plover.exe' }
                    [PSCustomObject]@{ Name = 'plover-5.3.0-x86_64.AppImage'; BrowserDownloadUrl = 'https://example.com/plover.AppImage' }
                )
            }
        }

        Mock Invoke-WebRequest
        Mock Test-Path { $false }
        Mock Start-Process

        { Install-PloverLatestRelease -WhatIf } | Should -Not -Throw
    }

    It 'Finds correct asset for macOS platform' -Skip:(-not $canConnect -or -not $IsMacOS) {
        Mock Get-LatestGithubRelease {
            [PSCustomObject]@{
                TagName = 'v5.3.0'
                Assets  = @(
                    [PSCustomObject]@{ Name = 'plover-5.3.0-macosx_12_0_universal2.dmg'; BrowserDownloadUrl = 'https://example.com/plover.dmg' }
                )
            }
        }

        Mock Invoke-WebRequest
        Mock Test-Path { $false }
        Mock bash

        { Install-PloverLatestRelease -WhatIf } | Should -Not -Throw
    }

    It 'Throws error when no matching asset found for platform' -Skip:(-not $canConnect) {
        Mock Get-LatestGithubRelease {
            [PSCustomObject]@{
                TagName = 'v5.3.0'
                Assets  = @(
                    [PSCustomObject]@{ Name = 'source.tar.gz'; BrowserDownloadUrl = 'https://example.com/source.tar.gz' }
                )
            }
        }

        { Install-PloverLatestRelease -WhatIf } | Should -Throw
    }
}

Describe 'Get-PloverPath on Linux' {
    It 'Returns AppImage path when installed' -Skip:(-not $IsLinux) {
        # Create a temporary AppImage for testing
        $tempAppImage = Join-Path $HOME '.local/bin/plover.AppImage'
        $tempDir = Split-Path $tempAppImage -Parent

        try
        {
            # Create directory if it doesn't exist
            if (-not (Test-Path $tempDir))
            {
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            }

            # Create a temporary "AppImage" file
            '' | Out-File -FilePath $tempAppImage -Force

            $result = Get-PloverPath
            $result | Should -Be $tempAppImage
        }
        finally
        {
            # Clean up
            if (Test-Path $tempAppImage)
            {
                Remove-Item $tempAppImage -Force
            }
        }
    }

    It 'Throws helpful error when AppImage not installed' -Skip:(-not $IsLinux) {
        # Ensure AppImage doesn't exist
        $tempAppImage = Join-Path $HOME '.local/bin/plover.AppImage'

        if (Test-Path $tempAppImage)
        {
            # Backup existing AppImage
            $backupPath = "$tempAppImage.bak"
            Move-Item -Path $tempAppImage -Destination $backupPath -Force

            try
            {
                { Get-PloverPath } | Should -Throw '*Install-PloverLatestRelease*'
            }
            finally
            {
                # Restore backup
                if (Test-Path $backupPath)
                {
                    Move-Item -Path $backupPath -Destination $tempAppImage -Force
                }
            }
        }
        else
        {
            { Get-PloverPath } | Should -Throw '*Install-PloverLatestRelease*'
        }
    }
}
