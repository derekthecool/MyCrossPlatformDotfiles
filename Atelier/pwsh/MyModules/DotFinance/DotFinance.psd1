@{
    RootModule        = 'DotFinance.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'dda5d8a0-5722-4857-916a-c839d6884911'
    Author            = 'Derek Lomax'
    Description       = 'Personal finance module'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @()
    FunctionsToExport = @(
        'Get-Tithing'
    )
}
