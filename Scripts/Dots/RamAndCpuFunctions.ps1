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

function Get-CombinedCPUUsagePercentage {
    param(
        [int]$IntervalSeconds = 2  # Interval for measuring CPU usage
    )

    # Documentation can be included here as needed.

    # Capture initial CPU usage and timestamp
    $startCpuTimes = Get-Process | Select-Object Name, Id, @{Name='CPU';Expression={$_.TotalProcessorTime.TotalMilliseconds}}
    $startTime = Get-Date

    # Wait for the specified interval
    Start-Sleep -Seconds $IntervalSeconds

    # Capture CPU usage and timestamp again
    $endCpuTimes = Get-Process | Select-Object Name, Id, @{Name='CPU';Expression={$_.TotalProcessorTime.TotalMilliseconds}}
    $endTime = Get-Date

    # Calculate the difference in CPU time and the elapsed interval
    $cpuUsageDetails = $endCpuTimes | ForEach-Object {
        $process = $_
        $startCpu = $startCpuTimes | Where-Object {$_.Id -eq $process.Id} | Select-Object -ExpandProperty CPU -Unique

        if ($startCpu -ne $null) {
            $cpuTimeDiff = $process.CPU - $startCpu
            $elapsedTime = ($endTime - $startTime).TotalMilliseconds
            $cpuPercentage = ($cpuTimeDiff / $elapsedTime) * 100 * [Environment]::ProcessorCount

            # Create a custom PSObject for each process
            [PSCustomObject]@{
                Name = $process.Name
                Id = $process.Id
                CPU_Usage_Percentage = [Math]::Round($cpuPercentage, 2)
            }
        }
    }

    # Combine processes by Name, summing CPU usages and collecting IDs
    $combinedUsage = $cpuUsageDetails |
        Group-Object Name |
        ForEach-Object {
            $totalCpu = ($_.Group | Measure-Object -Property CPU_Usage_Percentage -Sum).Sum
            $allIds = ($_.Group | ForEach-Object { $_.Id }) -join ', '

            # Output combined details
            [PSCustomObject]@{
                Name = $_.Name
                Ids = $allIds
                Total_CPU_Usage_Percentage = [Math]::Round($totalCpu, 2)
            }
        }

    # Output the results sorted by Total CPU usage percentage in descending order
    $combinedUsage | Sort-Object Total_CPU_Usage_Percentage -Descending| select-object -First 10 | Format-Table -AutoSize
}
