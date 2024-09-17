# $actualGit = Get-Command git

# Function to using my git bare repo for my windows config files
function dot
{
    # Create a copy of the arguments array to manipulate
    $arguments = $args

    # Check if the first argument is 'git' and remove it if so
    # This will help steno speed greatly. Now I can just run commands like 'dot git status --short'
    # And it'll work
    if ($arguments.Length -gt 0 -and $arguments[0] -eq 'git')
    {
        $arguments = $arguments[1..($arguments.Length - 1)]
    }

    Invoke-Expression "git --git-dir=$HOME/.cfg --work-tree=$HOME @arguments"
    # $gitCommand = "git --git-dir=$HOME/.cfg --work-tree=$HOME @arguments
    # Write-Host "Sending git command"
    # Write-Host "$gitCommand"
    # Invoke-Expression "$gitCommand"
}

# Helpful alias for typos like: dotgit status
New-Alias -Name dotgit -Value dot -ErrorAction SilentlyContinue

# Clone and setup the dotfiles repository with force checkout
function Initialize-Dotfiles
{
    param (
        [string]$RepositoryUrl = 'git@github.com:derekthecool/MyCrossPlatformDotfiles.git',
        [string]$ConfigDirectory = "$HOME/.cfg"
    )

    if(-not (Get-Command git -ErrorAction SilentlyContinue))
    {
        Write-Host 'Git is not installed, install that first then try again'
        return 1
    }

    # Clone the repository as a bare repository if not already cloned
    if (-not (Test-Path $ConfigDirectory))
    {
        git clone --bare --recurse-submodules $RepositoryUrl $ConfigDirectory
    }

    # Create a backup directory
    $backupDir = "$HOME/.config-backup"
    if (-not (Test-Path $backupDir))
    {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }

    # Force checkout to overwrite conflicting dotfiles in the work tree
    dot checkout --force

    # Configure git to not show untracked files
    dot config status.showUntrackedFiles no

    # Run this script to install all my favorite powershell modules
    ./$HOME/Scripts/Bootstrap-RequiredModules.ps1

    Write-Host 'Dotfiles are initialized and ready.'
}

function Clone-GitRepository
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(https://|ssh://|git@).*$')]
        [string]$RepoURL,

        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory
    )

    try
    {

        # Ensure the target directory exists, creating any necessary parent directories
        if (Test-Path -Path $TargetDirectory -ErrorAction SilentlyContinue)
        {
            if($(git rev-parse --is-inside-work-tree) -match 'true')
            {
                Write-Host "Directory: $TargetDirectory is already a git repository" -ForegroundColor Green
                return 'complete'
            } else
            {
                Write-Host 'Directory: $Target exists, but is not a git repository, exiting' -ForegroundColor Yellow
                return 'check on existing files and try again'
            }
        }

        # Clone the repository
        Write-Host "Cloning repository $RepoURL to $TargetDirectory"
        git clone --recurse-submodules "$RepoURL" "$TargetDirectory"
        return 'complete'
    } catch
    {
        Write-Error "Failed to clone the repository. Error: $_"
        return 'error'
    }
}

function Get-NeovimConfigurationDirectory
{
    if($IsWindows)
    {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) -ChildPath 'nvim'
    } else
    {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) -ChildPath 'nvim'
    }
    return $cloneTargetPath
}

# https://github.com/derekthecool/stimpack
function Get-NeovimConfiguration
{
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/stimpack.git'

    $cloneTargetPath = Get-NeovimConfigurationDirectory
    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

function Get-WeztermConfigurationDirectory
{
    # This path is the same for windows and Linux
    return "$HOME/.config/wezterm"
}

# https://github.com/derekthecool/WeztermStimpack
function Get-WeztermConfiguration
{
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/WeztermStimpack.git'

    $cloneTargetPath = Get-WeztermConfigurationDirectory
    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

function Get-PloverConfigurationDirectory
{
    if($IsWindows)
    {
        # Windows default is uppercase for Plover, but case does not matter on windows file names
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) -ChildPath 'Plover'
    } else
    {
        # Make sure to use lowercase
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) -ChildPath 'plover'
    }
    return $cloneTargetPath
}

# https://github.com/derekthecool/PloverStenoDictionaries
function Get-PloverConfiguration
{
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/PloverStenoDictionaries.git'

    $cloneTargetPath = Get-PloverConfigurationDirectory
    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

function Get-ExercismConfigurationDirectory
{
    return "$HOME/Exercism"
}

# https://github.com/derekthecoolther/ExercismProgramming
function Get-ExercismConfiguration
{
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/ExercismProgramming.git'

    # This path is the same for windows and Linux
    $cloneTargetPath = Get-ExercismConfigurationDirectory
    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

function Get-AllConfigurations
{
    Get-NeovimConfiguration
    Get-WeztermConfiguration
    Get-PloverConfiguration
    Get-ExercismConfiguration
}

function dots
{
    $repositories = @(
        Get-NeovimConfigurationDirectory
        Get-WeztermConfigurationDirectory
        Get-PloverConfigurationDirectory
        Get-ExercismConfigurationDirectory
    )

    $arguments = $args

    # Save current directory
    Push-Location

    $repositories | ForEach-Object {
        if(-not $(Test-Path "$_"))
        {
            Write-Error "Git repository path $_ does not exist"
            continue
        }

        Set-Location "$_"

        # Run git on this repository with the arguments specified
        $command = "git $arguments"
        Write-Host "$(Get-Location): $command"
        Invoke-Expression -Command "$command"
        Write-Host ''
    }

    # Lastly run the dot files repository command as well
    $command = "dot $args"
    Write-Host 'On dotfiles bare repo'
    Invoke-Expression -Command "$command"

    # Restore location
    Pop-Location
}
