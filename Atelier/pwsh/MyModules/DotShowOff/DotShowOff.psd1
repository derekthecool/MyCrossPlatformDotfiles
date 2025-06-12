@{
    RootModule        = 'DotShowOff.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '3a3a6a4b-525d-4f14-99e1-7beade4185ae'
    Author            = 'Derek Lomax'
    Description       = 'Simple function to utilize a TUI to help with inspecting powershell objects'
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
        'Show'
    )
    FunctionsToExport = @(
        'Show-Object'
    )
}

