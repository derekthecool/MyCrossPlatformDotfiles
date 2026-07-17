@{
    RootModule        = 'DotSystem.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '6e6dca21-00f0-4385-b91f-18df86f1a415'
    Author            = 'Derek Lomax'
    Description       = 'System diagnostics, profiling, and verified download helpers'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'system', 'profiling', 'benchmark', 'cpu', 'memory', 'download')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @()
    FunctionsToExport = @(
        'Get-Benchmark'
        'Get-BenchmarkTotalMilliseconds'
        'Get-CombinedCPUUsagePercentage'
        'Get-TopMemoryProcesses'
        'Get-ISO'
        'Get-ISOFilename'
    )
}
