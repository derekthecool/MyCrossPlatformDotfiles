$script:DevSyncExcludes = @(
    'build'
    '.build'
    '.dart_tool'
    'node_modules'
    '.next'
    'public'
    '.fvm'
    '.esphome'
    '.pub-cache'
    '.cache'
    'target'
    '.pio'
    '.venv'
    '__pycache__'
    # Submodule working trees, re-fetchable on the remote via git
    'lib/chibios'
    'lib/chibios-contrib'
    'vendor/qmk_firmware'
)

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

        [string]
        $LocalRoot = (Join-Path $HOME 'HomeServer'),

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

    $LocalRoot = (Resolve-Path -LiteralPath $LocalRoot -ErrorAction SilentlyContinue).Path
    if (-not $LocalRoot)
    {
        New-Item -ItemType Directory -Path (Join-Path $HOME 'HomeServer') -Force | Out-Null
        $LocalRoot = (Resolve-Path -LiteralPath (Join-Path $HOME 'HomeServer')).Path
    }

    if ($LocalRoot -eq $HOME)
    {
        throw 'Refusing to sync into the home directory itself.'
    }

    $rsyncArgs = @(
        '-az'
        '--itemize-changes'
        '-e', 'ssh'
    )
    if ($DryRun) { $rsyncArgs += '--dry-run' }
    if ($Delete) { $rsyncArgs += '--delete' }
    foreach ($exclude in $script:DevSyncExcludes)
    {
        $rsyncArgs += "--exclude=$exclude"
    }

    foreach ($tree in $Trees)
    {
        if ($Direction -eq 'Pull')
        {
            $source = "${UserName}@${ComputerName}:/home/${UserName}/$tree/"
            $destination = Join-Path $LocalRoot $tree
        }
        else
        {
            $source = (Join-Path $HOME $tree) + '/'
            if (-not (Test-Path -LiteralPath $source))
            {
                Write-Warning "Skipping $tree, not found locally."
                continue
            }
            $destination = "${UserName}@${ComputerName}:/home/${UserName}/$tree"
        }

        Write-Host "[$Direction] $source -> $destination"
        $remote = $UserName + '@' + $ComputerName
        & rsync @rsyncArgs $source $destination
        if ($LASTEXITCODE -ne 0)
        {
            throw "rsync failed for $tree with exit code $LASTEXITCODE."
        }
    }
}
