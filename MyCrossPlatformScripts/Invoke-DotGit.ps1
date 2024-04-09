# Function to using my git bare repo for my windows config files
function dot {
    # Create a copy of the arguments array to manipulate
    $arguments = $args

    # Check if the first argument is 'git' and remove it if so
    # This will help steno speed greatly. Now I can just run commands like 'dot git status --short'
    # And it'll work
    if ($arguments.Length -gt 0 -and $arguments[0] -eq 'git') {
        $arguments = $arguments[1..($arguments.Length - 1)]
    }

    # Run git command with modified arguments
    git --git-dir="$HOME/.cfg" --work-tree="$HOME" @arguments
}

# Helpful alias for typos like: dotgit status
New-Alias -Name dotgit -Value dot -ErrorAction SilentlyContinue

# Clone and setup the dotfiles repository with force checkout
function Initialize-Dotfiles {
    param (
        [string]$RepositoryUrl = 'git@github.com:derekthecool/MyCrossPlatformDotfiles.git',
        [string]$ConfigDirectory = "$HOME/.cfg"
    )

    if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host 'Git is not installed, install that first then try again'
        return 1
    }

    # Clone the repository as a bare repository if not already cloned
    if (-not (Test-Path $ConfigDirectory)) {
        git clone --bare --recurse-submodules $RepositoryUrl $ConfigDirectory
    }

    # Create a backup directory
    $backupDir = "$HOME/.config-backup"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }

    # Force checkout to overwrite conflicting dotfiles in the work tree
    dot checkout --force

    # Configure git to not show untracked files
    dot config status.showUntrackedFiles no

    Write-Host 'Dotfiles are initialized and ready.'
}
