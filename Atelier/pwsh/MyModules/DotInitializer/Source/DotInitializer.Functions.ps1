function Set-PackageProviderPriority
{
    $Providers = Get-PackageProvider
    $Providers | Where-Object { $_.Name -match 'PSResourceGet|WinGet' } | ForEach-Object { $_.Priority -= 20 }
    $Providers | Where-Object { $_.Name -match 'Scoop|Apt' } | ForEach-Object { $_.Priority -= 25 }
}

function Get-DotPackageList
{
    @(
            # # Essential
            # Scoop
            @{ Name = 'neovim' },
            @{ Name = 'pwsh' },
            @{ Name = 'wezterm' },
            @{ Name = 'autohotkey' },
            @{ Name = 'flutter' },
            @{ Name = 'gh' },
            @{ Name = 'go' },
            @{ Name = 'nodejs' },
            @{ Name = 'podman' },
            @{ Name = 'docker-compose' },
            @{ Name = 'python' },
            @{ Name = 'starship' },
            @{ Name = 'rust' },

            # Yazi https://yazi-rs.github.io/docs/installation/#windows
            @{ Name = 'yazi' },
            @{ Name = 'ffmpeg' },
            @{ Name = '7zip' },
            @{ Name = 'jq' },
            @{ Name = 'poppler' },
            @{ Name = 'fd' },
            @{ Name = 'ripgrep' },
            @{ Name = 'fzf' },
            @{ Name = 'zoxide' },
            @{ Name = 'imagemagick' },

            # Other important packages
            @{ Name = 'curl' },
            @{ Name = 'exercism' },
            @{ Name = 'netcat' },
            @{ Name = 'nmap' },
            @{ Name = 'okular' },
            @{ Name = 'putty' },
            @{ Name = 'stylua' },
            @{ Name = 'unrar' },
            @{ Name = 'vlc' },
            @{ Name = 'yt-dlp' },
            @{ Name = 'mpv' }


        # Linux only: TODO: (Derek Lomax) 3/28/2025 10:20:23 AM, This section will need to lot of work to support Ubuntu, Arch, etc.
        if ($IsLinux)
        {
        }

        # TODO: (Derek Lomax) 3/28/2025 10:28:47 AM, Consider grouping by functionality such as web, terminal, programming languages etc. instead of OS.
        if ($IsWindows)
        {
            # Needed for WSL
            @{ Name = 'win32yank'; Provider = 'Scoop' },

            # Non-essential packages but still awesome
            @{ Name = 'adb' },
            @{ Name = 'btop' },
            @{ Name = 'busybox' },
            @{ Name = 'keypirinha' },
            @{ Name = 'lftp' },
            @{ Name = 'make' },
            @{ Name = 'mosquitto' },
            @{ Name = 'musescore' },
            @{ Name = 'mysql-lts' },
            @{ Name = 'ntop' },
            @{ Name = 'nuget' },
            @{ Name = 'obsidian' },
            @{ Name = 'protobuf' },
            @{ Name = 'simplyserial' },
            @{ Name = 'sqlite' },
            @{ Name = 'termscp' },
            @{ Name = 'twilio-cli' },
            @{ Name = 'gcc' },

            # applications that seem to have problems installing
            # Works with scoop install musicbee but fails with anypackage
            # @{ Name = 'musicbee' },

            # Winget
            @{ Name = 'Microsoft.Sqlcmd'; Provider = 'WinGet' }
            @{ Name = 'Microsoft.DotNet.SDK.8'; Provider = 'WinGet' }
            @{ Name = 'Microsoft.DotNet.SDK.9'; Provider = 'WinGet' }
            @{ Name = 'Microsoft.DotNet.SDK.Preview'; Provider = 'WinGet' }
            # Scoop is not the best option for web browsers - profiles get messy
            @{ Name = 'Brave.Brave'; Provider = 'WinGet' }
            @{ Name = 'Zoom.Zoom'; Provider = 'WinGet' }
        }

        if ($IsMacOS)
        {
        }

        # # Dotnet tools: supported on every OS
        @{Name = 'csharpier'; Provider = '.NET tool' },
        @{Name = 'csharprepl'; Provider = '.NET Tool' },
        @{Name = 'dotnet-ef'; Provider = '.NET Tool' },
        @{Name = 'dotnet-script'; Provider = '.NET Tool' },
        @{Name = 'fantomas'; Provider = '.NET Tool' },
        @{Name = 'ilspycmd'; Provider = '.NET Tool' },
        @{Name = 'terminalguidesigner'; Provider = '.NET Tool' },
        @{Name = 'vpk'; Provider = '.NET Tool' }
    )
}

function Get-DotPackages
{
    Set-PackageProviderPriority
    Get-DotPackageList | ForEach-Object {
        $Name = $_.Name
        $Provider = $_.Provider
        Get-Variable _ | Write-Verbose
        if ([string]::IsNullOrEmpty($Name))
        {
            Write-Host "Package name is empty, skipping"
        } else
        {
            Get-Package @_ -ErrorAction Continue
        }
    }
}

function Install-DotPackages
{
    Set-PackageProviderPriority
    Get-PackageProvider
    $packages = Get-DotPackageList

    foreach ($package in $packages)
    {
        $Name = $package.Name
        if ([string]::IsNullOrEmpty($Name))
        {
            Write-Host "Package name is empty, skipping"
        } else
        {
            Install-Package @package -ErrorAction Continue -Verbose

            # Add explicit return when last package is found, GitHub actions is not exiting
            if ($Name -eq 'vpk' -and $env:CI)
            {
                Write-Host "Last package found, exiting"
                break
            }
        }
    }

    Write-Host "End of Install-DotPackages"
    Write-Verbose "End of Install-DotPackages"
}

function Update-DotPackages
{
    throw 'Not implemented'
}

function Update-DotPackages
{
    Write-Host "This function needs to be implemented"
    throw 'Not implemented'
}
