@{
    RootModule        = 'Dots.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '463ce966-d7ad-4cde-9874-cf133833f073'
    Author            = 'Derek Lomax'
    Copyright         = '(c) Derek Lomax. All rights reserved.'
    Description       = 'Powerful dot file collection module'
    FunctionsToExport = @(
        'ffmpeg-ReduceVideoSize'
        'Invoke-Mysql'
        'Convert-FileToHexString'
        'Expand-Number'
        'Get-BytesToSize'
        'Get-SerialPort'
        'Add-MasonToolsToPath'
        'Get-DotnetOutdatedPackage'
        'CustomSortOrder'
        'Get-GeneralCompletion'
        'Use-Kroger'
        'Use-SpoonacularApi'
        'Start-VSCompiler'
        'Get-ISO'
        'Get-ISOFilename'
        'Get-Benchmark'
        'Get-BenchmarkTotalMilliseconds'
        'Get-CombinedCPUUsagePercentage'
        'Get-TopMemoryProcesses'
        'Watch-FileChange'
    )
    AliasesToExport   = @(
        'ports'
        'number'
    )
}
