@{
    RootModule        = 'DotYazi.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '097023b3-18dd-41ee-864c-05d4a392ab92'
    Author            = 'Derek Lomax'
    Description       = 'Helper for loading and configuring yazi'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.
    CmdletsToExport   = @()
    FunctionsToExport = @(
        'y'
    )
}
