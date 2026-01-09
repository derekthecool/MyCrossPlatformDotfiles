@{
    RootModule        = 'DotFunctional.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '2cfbaa2f-a382-44de-8350-2d9619befb8d'
    Author            = 'Derek Lomax'
    Description       = 'Functional library for an easier time with map, filter, reduce, zip etc.'
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
        'zip'
    )
    FunctionsToExport = @(
        'Format-Pairs'
    )
}

