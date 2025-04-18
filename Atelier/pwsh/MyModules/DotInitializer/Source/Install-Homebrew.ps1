function Install-Homebrew {
    [CmdletBinding()]
    param()

    try {
        if($IsWindows)
        {
            Write-Error "Windows is not supported"
            return
        }

        # Check if Homebrew is already installed
        if (Get-Command brew -ErrorAction SilentlyContinue) {
            Write-Host "Homebrew is already installed."
            return
        }

        # Install Homebrew
        Write-Host "Installing Homebrew..."
        bash -c "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash"

        # Set up Homebrew environment
        if ($IsMacOS) {
            $brewPath = "/opt/homebrew/bin/brew"
        } elseif ($IsLinux) {
            $brewPath = "/home/linuxbrew/.linuxbrew/bin/brew"
        }

        if (Test-Path $brewPath) {
            $shellEnvCmd = "$brewPath shellenv"
            Invoke-Expression (& $brewPath shellenv)
            Write-Host "Homebrew installed and environment configured for current session."
        } else {
            Write-Warning "Homebrew installed, but path not found. You may need to add it manually to your shell profile."
        }

    } catch {
        Write-Error "An error occurred during installation: $_"
    }
}
