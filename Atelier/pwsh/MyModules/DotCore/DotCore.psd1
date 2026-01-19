@{
    RootModule        = 'DotCore.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'c188bcf0-9fba-460d-befd-001c5ff45abf'
    Author            = 'Derek Lomax'
    Description       = 'Module for simple, core powershell utility functions'
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
        'join'
    )
    FunctionsToExport = @(
        'Join-Item'
        'ConvertFrom-Xml'
        'Find-DuplicateFile'
    )
}
