Measure-Script -Path $PROFILE

function Get-AverageProfileStartupTime {
    $a = 0
    $totalTimes = 10
    1 .. $totalTimes | ForEach-Object {
        Write-Progress -Id 1 -Activity 'profile' -PercentComplete $_
        $a += (Measure-Command {
                pwsh -command 1
            }).TotalMilliseconds
    }
    Write-Progress -Id 1 -Activity 'profile' -Completed
    $a/$totalTimes - $p
}

Write-Host 'Getting average profile startup time'
Get-AverageProfileStartupTime
