@{
    RootModule        = 'DotBeautiful.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a616240a-5394-4c60-b2d5-f345ff624e01'
    Author            = 'Derek Lomax'
    Description       = 'Formatting and display helpers using EZOut. Basically a mini Posh: formatting only module.'
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
        'No-functions'
    )
}

