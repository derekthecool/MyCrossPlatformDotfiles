function Get-DotPackageList
{
    @(
        # All platforms
        @{ Name = 'neovim' }

        # Linux only: TODO: (Derek Lomax) 3/28/2025 10:20:23 AM, This section will need to lot of work to support Ubuntu, Arch, etc.
        if($IsLinux)
        {
        }

        # TODO: (Derek Lomax) 3/28/2025 10:28:47 AM, Consider grouping by functionality such as web, terminal, programming languages etc. instead of OS.
        if($IsWindows)
        {
            # Scoop
            # # Essential
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

            # Non-essential packages but still awesome
            @{ Name = '7zip' },
            @{ Name = 'adb' },
            @{ Name = 'android-studio' },
            @{ Name = 'bat' },
            @{ Name = 'btop' },
            @{ Name = 'busybox' },
            @{ Name = 'curl' },
            @{ Name = 'exercism' },
            @{ Name = 'ffmpeg' },
            @{ Name = 'gcc' },
            @{ Name = 'gdb' },
            @{ Name = 'jq' },
            @{ Name = 'keypirinha' },
            @{ Name = 'lftp' },
            @{ Name = 'luarocks' },
            @{ Name = 'make' },
            @{ Name = 'mosquitto' },
            @{ Name = 'mpv' },
            @{ Name = 'musescore' },
            @{ Name = 'musicbee' },
            @{ Name = 'mysql-lts' },
            @{ Name = 'mysql-shell' },
            @{ Name = 'netcat' },
            @{ Name = 'nmap' },
            @{ Name = 'ntop' },
            @{ Name = 'nuget' },
            @{ Name = 'obs-studio' },
            @{ Name = 'obsidian' },
            @{ Name = 'okular' },
            @{ Name = 'poppler' },
            @{ Name = 'protobuf' },
            @{ Name = 'putty' },
            @{ Name = 'qpdf' },
            @{ Name = 'raspberry-pi-imager' },
            @{ Name = 'ripgrep' },
            @{ Name = 'rust' },
            @{ Name = 'simplyserial' },
            @{ Name = 'sqlite' },
            @{ Name = 'stylua' },
            @{ Name = 'termscp' },
            @{ Name = 'termshark' },
            @{ Name = 'twilio-cli' },
            @{ Name = 'unrar' },
            @{ Name = 'vlc' },
            @{ Name = 'wireshark' },
            @{ Name = 'yarn' },
            @{ Name = 'yt-dlp' },
            @{ Name = 'zoxide' }

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
    Get-PackageProvider -Verbose
    Get-PackageProvider | Write-Verbose

    Get-Module *AnyPackage* -Verbose
    Get-Module *AnyPackage* | Write-Verbose

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
            Install-Package @_ -ErrorAction Continue
        }
    }

    Get-Package
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
