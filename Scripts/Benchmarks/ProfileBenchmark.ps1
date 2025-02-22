$totalTimes = 3

function Get-AverageProfileStartupTime
{
    $a = 0
    $Activity = 'Load pwsh with profile'
    1 .. $totalTimes | ForEach-Object {
        Write-Progress -Id 1 -Activity $Activity -PercentComplete (($_ / $totalTimes) * 100)
        $a += (Measure-Command { pwsh -Command 1 }).TotalMilliseconds
    }
    Write-Progress -Id 1 -Activity $Activity -Completed
    $a / $totalTimes - $p
}

function Get-AveragePwshStartupTime
{
    $a = 0
    $Activity = 'Load pwsh with NO profile'
    1 .. $totalTimes | ForEach-Object {
        Write-Progress -Id 1 -Activity $Activity -PercentComplete (($_ / $totalTimes) * 100)
        $a += (Measure-Command { pwsh -NoProfile -Command 1 }).TotalMilliseconds
    }
    Write-Progress -Id 1 -Activity $Activity -Completed
    $a / $totalTimes - $p
}

function Get-ProfileLoadTotal
{
    (Get-AverageProfileStartupTime) - (Get-AveragePwshStartupTime)
}
