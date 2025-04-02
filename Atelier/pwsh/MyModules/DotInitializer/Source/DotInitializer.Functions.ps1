function Set-PackageProviderPriority
{
    # TODO: (Derek Lomax) Sat 29 Mar 2025 09:01:01 PM MDT, The DotNet.Tool provider is not respecting the priority
    # Make main package providers higher priority
    $Providers = Get-PackageProvider
    $Providers | Where-Object { $_.Name -match 'PSResourceGet|WinGet' } | ForEach-Object{ $_.Priority -= 20 }
    $Providers | Where-Object { $_.Name -match 'Scoop|Apt' } | ForEach-Object{ $_.Priority -= 25 }
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
            @{ Name = 'neovim' },
            @{ Name = 'pwsh' },
            @{ Name = 'wezterm' },
            @{ Name = 'autohotkey' },
            @{ Name = 'flutter' },
            @{ Name = 'gh' },
            # Git will be installed for scoop in ./Install-Scoop.ps1
            # @{ Name = 'git' },
            @{ Name = 'go' },
            @{ Name = 'nodejs' },
            @{ Name = 'podman' },
            @{ Name = 'python' },
            @{ Name = 'starship' },
            @{ Name = 'fzf' },
            @{ Name = 'ripgrep' },
            @{ Name = 'rust' },

            # Non-essential packages but still awesome
            @{ Name = '7zip' },
            @{ Name = 'adb' },
            @{ Name = 'btop' },
            @{ Name = 'busybox' },
            @{ Name = 'curl' },
            @{ Name = 'exercism' },
            @{ Name = 'ffmpeg' },
            @{ Name = 'gcc' },
            @{ Name = 'jq' },
            @{ Name = 'keypirinha' },
            @{ Name = 'lftp' },
            @{ Name = 'make' },
            @{ Name = 'mosquitto' },
            @{ Name = 'mpv' },
            @{ Name = 'musescore' },
            @{ Name = 'mysql-lts' },
            @{ Name = 'netcat' },
            @{ Name = 'nmap' },
            @{ Name = 'ntop' },
            @{ Name = 'nuget' },
            @{ Name = 'obsidian' },
            @{ Name = 'okular' },
            @{ Name = 'protobuf' },
            @{ Name = 'putty' },
            @{ Name = 'simplyserial' },
            @{ Name = 'sqlite' },
            @{ Name = 'stylua' },
            @{ Name = 'termscp' },
            @{ Name = 'twilio-cli' },
            @{ Name = 'unrar' },
            @{ Name = 'vlc' },
            @{ Name = 'yt-dlp' },
            @{ Name = 'zoxide' },

            # applications that seem to have problems installing
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

        if($IsMacOS)
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
