@{
    RootModule        = 'DotDatabase.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '53b3f550-e37f-439c-a96a-1f021669bc3c'
    Author            = 'Derek Lomax'
    Description       = 'Database helper functions (MySQL via SimplySql)'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'mysql', 'database', 'simplysql')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @()
    FunctionsToExport = @(
        'Invoke-Mysql'
    )
}
