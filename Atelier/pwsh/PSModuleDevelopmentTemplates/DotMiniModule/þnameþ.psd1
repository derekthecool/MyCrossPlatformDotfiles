@{
    RootModule        = 'þnameþ.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'þ!guid!þ'
    Author            = 'Derek Lomax'
    Description       = 'þDescriptionþ'
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
        'þFirst-FunctionAliasþ'
    )
    FunctionsToExport = @(
        'þFirst-Functionþ'
    )
}

