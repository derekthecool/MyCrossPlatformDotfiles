function Get-GitRepositoryConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(https://.*|ssh://.*|git@.*)$')]
        [string]$RepoURL,

        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory
    )

    try {
        # Ensure the target directory exists, creating any necessary parent directories
        if (-not (Test-Path -Path $TargetDirectory)) {
            Write-Host "Creating target directory: $TargetDirectory"
            New-Item -Path $TargetDirectory -ItemType Directory -Force | Out-Null
        }

        # Clone the repository
        Write-Host "Cloning repository from $RepoURL to $TargetDirectory"
        git clone $RepoURL $TargetDirectory
    } catch {
        Write-Error "Failed to clone the repository. Error: $_"
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

    New-Item -ItemType Directory "$HOME/.config" -ErrorAction SilentlyContinue
    git clone "$RepoURL" "$cloneTargetPath"
}

# https://github.com/derekthecool/WeztermStimpack
function Get-WeztermConfiguration {
    [Parameter()]
    [string]$RepoURL = 'git@github.com:derekthecool/WeztermStimpack.git'

    if($IsWindows) {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) -ChildPath 'nvim'
    } else {
        $cloneTargetPath = Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) -ChildPath 'nvim'
    }

    New-Item -ItemType Directory "$HOME/.config" -ErrorAction SilentlyContinue
    git clone "$RepoURL" "$cloneTargetPath"
}
