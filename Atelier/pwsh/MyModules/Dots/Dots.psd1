@{
    RootModule        = 'Dots.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '463ce966-d7ad-4cde-9874-cf133833f073'
    Author            = 'Derek Lomax'
    Copyright         = '(c) Derek Lomax. All rights reserved.'
    Description       = 'Powerful dot file collection module'
    FunctionsToExport = @(
        'Get-Benchmark'
        'Get-BenchmarkTotalMilliseconds'
        'Add-MasonToolsToPath'
        'Get-AllConfigurations'
        'Get-TopMemoryProcesses'
        'Get-CombinedCPUUsagePercentage'
        'Watch-FileChange'
        'Get-SerialPort'
    )
    AliasesToExport   = @(
        'ports'
    )
}
