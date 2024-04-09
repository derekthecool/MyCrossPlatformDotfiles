function Clone-GitRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(https://|ssh://|git@).*$')]
        [string]$RepoURL,

        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory
    )

    try {

        # Ensure the target directory exists, creating any necessary parent directories
        if (Test-Path -Path $TargetDirectory -ErrorAction SilentlyContinue)  {
            if($(git rev-parse --is-inside-work-tree) -match 'true') {
                Write-Host "Directory: $TargetDirectory is already a git repository" -ForegroundColor Green
                return 'complete'
            } else {
                Write-Host 'Directory: $Target exists, but is not a git repository, exiting' -ForegroundColor Yellow
                return 'check on existing files and try again'
            }
        }

        # Clone the repository
        Write-Host "Cloning repository $RepoURL to $TargetDirectory"
        git clone --recurse-submodules "$RepoURL" "$TargetDirectory"
        return 'complete'
    } catch {
        Write-Error "Failed to clone the repository. Error: $_"
        return 'error'
    }
}

# https://github.com/derekthecool/stimpack
function Get-NeovimConfiguration {
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/stimpack.git'

    if($IsWindows) {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) -ChildPath 'nvim'
    } else {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) -ChildPath 'nvim'
    }

    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

# https://github.com/derekthecool/WeztermStimpack
function Get-WeztermConfiguration {
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/WeztermStimpack.git'

    # This path is the same for windows and Linux
    $cloneTargetPath = "$HOME/.config/wezterm"
    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

# https://github.com/derekthecool/PloverStenoDictionaries
function Get-PloverConfiguration {
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/PloverStenoDictionaries.git'

    if($IsWindows) {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) -ChildPath 'Plover'
    } else {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) -ChildPath 'Plover'
    }

    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

# https://github.com/derekthecoolther/ExercismProgramming
function Get-ExercismConfiguration {
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/ExercismProgramming.git'

    # This path is the same for windows and Linux
    $cloneTargetPath = "$HOME/Exercism"
    return Clone-GitRepository -RepoURL "$RepoURL" -TargetDirectory "$cloneTargetPath"
}

function Get-AllConfigurations {
    Get-NeovimConfiguration
    Get-WeztermConfiguration
    Get-PloverConfiguration
    Get-ExercismConfiguration
}
