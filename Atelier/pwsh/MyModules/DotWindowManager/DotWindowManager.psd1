@{
    RootModule        = 'DotWindowManager.psm1'
    ModuleVersion     = '0.1.0'
    Author            = 'Derek Lomax'
    Description       = 'Unified window manager configuration for Whim and AwesomeWM'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'window-manager', 'whim', 'awesomewm')
        }
    }
    VariablesToExport = ''
    CmdletsToExport   = @()
    AliasesToExport   = @()
    FunctionsToExport = @(
        'Get-WM'
        'Add-WMRoute'
        'Add-WMFilter'
        'Get-WindowDetails'
    )
}
