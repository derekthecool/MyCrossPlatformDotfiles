# Flutter apps keep their release artifacts (APK/AAB) in <project>/build/app/outputs;
# those must survive the 'build' excludes below. rsync never descends into an excluded
# directory, so each parent segment needs an explicit include first, and '*/build/**'
# below re-prunes the rest of each build tree.
$script:DevSyncIncludes = @(
    '*/build/'
    '*/build/app/'
    '*/build/app/outputs/'
    '*/build/app/outputs/**'
)

$script:DevSyncExcludes = @(
    'build'
    '.build'
    '.dart_tool'
    'node_modules'
    '.next'
    '.fvm'
    '.esphome'
    '.pub-cache'
    '.cache'
    'target'
    '.pio'
    '.venv'
    '__pycache__'
    # Everything under a project build/ except the outputs includes above
    '*/build/**'
    # Submodule working trees, re-fetchable on the remote via git
    'lib/chibios'
    'lib/chibios-contrib'
    'vendor/qmk_firmware'
    # Hugo build output only; tracked files named public/ elsewhere must sync
    'lomax_simple_software_website/public'
)

function Get-DevSyncLocalTree
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Tree
    )

    if ([IO.Path]::IsPathRooted($Tree))
    {
        throw "Refusing to sync '$Tree' - trees must be relative folder names under $HOME."
    }

    $localTree = Join-Path $HOME $Tree
    $relative = [IO.Path]::GetRelativePath($HOME, $localTree)
    if ($relative -eq '.' -or $relative -like '..*')
    {
        throw "Refusing to sync '$Tree' - trees must be folders under $HOME, not the home directory itself."
    }

    $localTree
}

function Sync-Dev
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,

        [string]
        $UserName = 'derek',

        [ValidateSet('Pull', 'Push')]
        [string]
        $Direction = 'Pull',

        [string[]]
        $Trees = @('LSS', 'projects'),

        [switch]
        $DryRun,

        [switch]
        $Delete
    )

    foreach ($tool in 'rsync', 'ssh')
    {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue))
        {
            throw "$tool is required but was not found in PATH."
        }
    }

    $rsyncArgs = @(
        '-az'
        '--itemize-changes'
        '-e', 'ssh'
    )
    if ($DryRun) { $rsyncArgs += '--dry-run' }
    if ($Delete) { $rsyncArgs += '--delete' }
    foreach ($include in $script:DevSyncIncludes)
    {
        $rsyncArgs += "--include=$include"
    }
    foreach ($exclude in $script:DevSyncExcludes)
    {
        $rsyncArgs += "--exclude=$exclude"
    }

    foreach ($tree in $Trees)
    {
        $localTree = Get-DevSyncLocalTree -Tree $tree
        if ($Direction -eq 'Pull')
        {
            $source = "${UserName}@${ComputerName}:/home/${UserName}/$tree/"
            $destination = $localTree
        } else
        {
            $source = $localTree + '/'
            if (-not (Test-Path -LiteralPath $source))
            {
                Write-Warning "Skipping $tree, not found locally."
                continue
            }
            $destination = "${UserName}@${ComputerName}:/home/${UserName}/$tree"
        }

        Write-Host "[$Direction] $source -> $destination"
        & rsync @rsyncArgs $source $destination
        if ($LASTEXITCODE -ne 0)
        {
            throw "rsync failed for $tree with exit code $LASTEXITCODE."
        }
    }
}
