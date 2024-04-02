function Get-TopMemoryProcesses {
    Get-Process | Group-Object -Property ProcessName |
        ForEach-Object {
            [PSCustomObject]@{
                ProcessName = $_.Name
                Mem_MB = [math]::Round(($_.Group|Measure-Object WorkingSet64 -Sum).Sum / 1MB, 0)
                ProcessCount = $_.Count
            }
        } | Sort-Object -desc Mem_MB | Select-Object -First 25
}

