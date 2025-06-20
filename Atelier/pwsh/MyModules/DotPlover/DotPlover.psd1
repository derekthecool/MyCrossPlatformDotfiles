@{
    RootModule        = 'DotPlover.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '57a53bc4-e79f-48d3-b6c5-2ad83ba6052b'
    Author            = 'Derek Lomax'
    Description       = 'Helpful module to run plover_console commands more easily'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @(
        'plover'
        'plover_console'
    )
    FunctionsToExport = @(
        'Get-PloverPath'
        'Invoke-Plover'
        'Get-TapeyTapePath'
        'Get-PloverConfigurationDirectory'
    )
}

