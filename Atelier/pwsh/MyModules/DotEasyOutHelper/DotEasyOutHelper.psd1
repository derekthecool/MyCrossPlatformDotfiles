@{
    RootModule        = 'DotEasyOutHelper.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '41339f68-7de4-4625-a174-8426292f2bd8'
    Author            = 'Derek Lomax'
    Description       = 'EZOut formatting module helper with interactive focus'
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
        'easy'
    )
    FunctionsToExport = @(
        'Use-EasyOut'
    )
}

