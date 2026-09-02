# Dumb pass-through wrapper: runs beets inside the beets-derek Docker image.
# Usage: Invoke-Beets <anything>   e.g. Invoke-Beets version, Invoke-Beets import -q /import
# Mounts (safety):
#   $HOME/.config/beets       -> /config   rw  (config, library.db, state, logs)
#   $HOME/Music/modify_source -> /import   ro  (source is IMPOSSIBLE to modify)
#   $HOME/Music/DerekMusic    -> /music    rw  (destination)
# ~/Music/original is never mounted. Works in pwsh 7+ on Linux and Windows.
function Invoke-Beets
{
    $dockerArgs = @(
        'run', '--rm', '-i'
        # -t only when stdout is a real TTY (docker errors on "the input device
        # is not a TTY" when piped/redirected)
        if (-not [Console]::IsOutputRedirected) { '-t' }
        '-v', "$HOME/.config/beets:/config"
        '-v', "$HOME/Music/modify_source:/import:ro"
        '-v', "$HOME/Music/DerekMusic:/music"
        'beets-derek:2.13.1'
    ) + $args
    docker @dockerArgs
}
