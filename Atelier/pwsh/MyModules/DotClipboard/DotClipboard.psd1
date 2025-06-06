@{
    RootModule        = 'DotClipboard.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '56ffda10-03e5-41d3-af90-8cf848df1897'
    Author            = 'Derek Lomax'
    Description       = 'Functions to help access and process clipboard text and convert to objects'
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
        'clipped'
    )
    FunctionsToExport = @(
        'Get-ClipboardAsArray'
    )
}

