# Function designed to basically be like dotnet watch
function Watch-FileChange {
    param(
        [string]$Path,
        [string]$Filter = '*',
        [scriptblock]$Action
    )

    Get-EventSubscriber | Unregister-Event

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Path
    $watcher.Filter = $Filter
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'

    # Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier FileCreated -Action $Action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier FileChanged -Action $Action
    # Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier FileDeleted -Action $Action
    # Register-ObjectEvent -InputObject $watcher -EventName Renamed -SourceIdentifier FileRenamed -Action $Action

    Write-Host "Monitoring changes to files in $Path with filter $Filter..."
    Write-Host 'Press CTRL+C to stop.'
}
