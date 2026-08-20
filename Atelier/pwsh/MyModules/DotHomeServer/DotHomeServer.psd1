@{
    RootModule        = 'DotHomeServer.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '8b4f411a-0878-43db-9abc-1b58dfa01991'
    Author            = 'Derek Lomax'
    Description       = 'Sync development trees with a remote dev box'
    PrivateData       = @{
        PSData        = @{
            Tags      = @('dots')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @()
    FunctionsToExport = @(
        'Sync-Dev'
    )
}
