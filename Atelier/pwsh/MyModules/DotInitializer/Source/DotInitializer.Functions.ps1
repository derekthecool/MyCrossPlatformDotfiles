function Set-PackageProviderPriority
{
    # TODO: (Derek Lomax) Sat 29 Mar 2025 09:01:01 PM MDT, The DotNet.Tool provider is not respecting the priority
    # Make main package providers higher priority
    $Providers = Get-PackageProvider
    $Providers | ForEach-Object{ $_.Priority = 50 }
    $Providers | Where-Object { $_.Name -match 'PSResourceGet|WinGet' } | ForEach-Object{ $_.Priority += 20 }
    $Providers | Where-Object { $_.Name -match 'Scoop|Apt' } | ForEach-Object{ $_.Priority += 25 }
}

function Get-DotPackageList
{
    @(

        # Linux only: TODO: (Derek Lomax) 3/28/2025 10:20:23 AM, This section will need to lot of work to support Ubuntu, Arch, etc.
        if($IsLinux)
        {
        }

        # TODO: (Derek Lomax) 3/28/2025 10:28:47 AM, Consider grouping by functionality such as web, terminal, programming languages etc. instead of OS.
        if($IsWindows)
        {
            # # Essential
            # Scoop
            @{ Name = 'neovim' ; Provider = 'Scoop';},
            @{ Name = 'pwsh' ; Provider = 'Scoop';},
            @{ Name = 'wezterm' ; Provider = 'Scoop';},
            @{ Name = 'autohotkey' ; Provider = 'Scoop';},
            @{ Name = 'flutter' ; Provider = 'Scoop';},
            @{ Name = 'gh' ; Provider = 'Scoop';},
            # Git will be installed for scoop in ./Install-Scoop.ps1
            # @{ Name = 'git' },
            @{ Name = 'go' ; Provider = 'Scoop';},
            @{ Name = 'nodejs' ; Provider = 'Scoop';},
            @{ Name = 'podman' ; Provider = 'Scoop';},
            @{ Name = 'python' ; Provider = 'Scoop';},
            @{ Name = 'starship' ; Provider = 'Scoop';},
            @{ Name = 'fzf' ; Provider = 'Scoop';},

            # Non-essential packages but still awesome
            @{ Name = '7zip' ; Provider = 'Scoop';},
            @{ Name = 'adb' ; Provider = 'Scoop';},
            @{ Name = 'android-studio' ; Provider = 'Scoop';},
            @{ Name = 'bat' ; Provider = 'Scoop';},
            @{ Name = 'btop' ; Provider = 'Scoop';},
            @{ Name = 'busybox' ; Provider = 'Scoop';},
            @{ Name = 'curl' ; Provider = 'Scoop';},
            @{ Name = 'exercism' ; Provider = 'Scoop';},
            @{ Name = 'ffmpeg' ; Provider = 'Scoop';},
            @{ Name = 'gcc' ; Provider = 'Scoop';},
            @{ Name = 'gdb' ; Provider = 'Scoop';},
            @{ Name = 'jq' ; Provider = 'Scoop';},
            @{ Name = 'keypirinha' ; Provider = 'Scoop';},
            @{ Name = 'lftp' ; Provider = 'Scoop';},
            @{ Name = 'luarocks' ; Provider = 'Scoop';},
            @{ Name = 'make' ; Provider = 'Scoop';},
            @{ Name = 'mosquitto' ; Provider = 'Scoop';},
            @{ Name = 'mpv' ; Provider = 'Scoop';},
            @{ Name = 'musescore' ; Provider = 'Scoop';},
            @{ Name = 'musicbee' ; Provider = 'Scoop';},
            @{ Name = 'mysql-lts' ; Provider = 'Scoop';},
            @{ Name = 'mysql-shell' ; Provider = 'Scoop';},
            @{ Name = 'netcat' ; Provider = 'Scoop';},
            @{ Name = 'nmap' ; Provider = 'Scoop';},
            @{ Name = 'ntop' ; Provider = 'Scoop';},
            @{ Name = 'nuget' ; Provider = 'Scoop';},
            @{ Name = 'obs-studio' ; Provider = 'Scoop';},
            @{ Name = 'obsidian' ; Provider = 'Scoop';},
            @{ Name = 'okular' ; Provider = 'Scoop';},
            @{ Name = 'poppler' ; Provider = 'Scoop';},
            @{ Name = 'protobuf' ; Provider = 'Scoop';},
            @{ Name = 'putty' ; Provider = 'Scoop';},
            @{ Name = 'qpdf' ; Provider = 'Scoop';},
            @{ Name = 'raspberry-pi-imager' ; Provider = 'Scoop';},
            @{ Name = 'ripgrep' ; Provider = 'Scoop';},
            @{ Name = 'rust' ; Provider = 'Scoop';},
            @{ Name = 'simplyserial' ; Provider = 'Scoop';},
            @{ Name = 'sqlite' ; Provider = 'Scoop';},
            @{ Name = 'stylua' ; Provider = 'Scoop';},
            @{ Name = 'termscp' ; Provider = 'Scoop';},
            @{ Name = 'termshark' ; Provider = 'Scoop';},
            @{ Name = 'twilio-cli' ; Provider = 'Scoop';},
            @{ Name = 'unrar' ; Provider = 'Scoop';},
            @{ Name = 'vlc' ; Provider = 'Scoop';},
            @{ Name = 'wireshark' ; Provider = 'Scoop';},
            @{ Name = 'yarn' ; Provider = 'Scoop';},
            @{ Name = 'yt-dlp' ; Provider = 'Scoop';},
            @{ Name = 'zoxide' ; Provider = 'Scoop';}

            # Winget
            @{ Name = 'Microsoft.DotNet.SDK.8'; Provider = 'WinGet' }
            @{ Name = 'Microsoft.DotNet.SDK.9'; Provider = 'WinGet' }
            @{ Name = 'Microsoft.DotNet.SDK.Preview'; Provider = 'WinGet' }
            # Scoop is not the best option for web browsers - profiles get messy
            @{ Name = 'Brave.Brave'; Provider = 'WinGet' }
            @{ Name = 'Zoom.Zoom'; Provider = 'WinGet' }
        }

        if($IsMacOS)
        {
        }

        # # Dotnet tools: supported on every OS
        # @{Name = 'csharpier'; Provider = '.NET tool' },
        # @{Name = 'csharprepl'; Provider = '.NET Tool' },
        # @{Name = 'dotnet-ef'; Provider = '.NET Tool' },
        # @{Name = 'dotnet-script'; Provider = '.NET Tool' },
        # @{Name = 'fantomas'; Provider = '.NET Tool' },
        # @{Name = 'ilspycmd'; Provider = '.NET Tool' },
        # @{Name = 'terminalguidesigner'; Provider = '.NET Tool' },
        # @{Name = 'vpk'; Provider = '.NET Tool' }
    )
}

function Get-DotPackages
{
    Set-PackageProviderPriority
    Get-DotPackageList | ForEach-Object {
        $Name = $_.Name
        $Provider = $_.Provider
        Get-Variable _ | Write-Verbose
        if([string]::IsNullOrEmpty($Name))
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
    Get-DotPackageList | ForEach-Object {

        Get-Variable _ -Verbose
        Get-Variable _ | Write-Verbose

        $Name = $_.Name
        $Provider = $_.Provider
        if([string]::IsNullOrEmpty($Name))
        {
            Write-Host "Package name is empty, skipping"
        } else
        {
            Install-Package @_ -ErrorAction Continue -Verbose
        }
    }
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
