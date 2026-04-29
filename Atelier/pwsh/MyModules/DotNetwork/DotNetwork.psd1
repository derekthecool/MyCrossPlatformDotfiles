@{
    RootModule        = 'DotNetwork.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '40265736-48bb-454a-918d-5b6732763859'
    Author            = 'Derek Lomax'
    Description       = 'Module for basic network functions'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'binary_module', 'compile_on_import')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.
    # This binary module will compile if dlls don't exist on module import!!!

    CmdletsToExport   = @(
        'Get-WifiAccessPoint'
    )
    AliasesToExport   = @(
        'gwap'
    )
    FunctionsToExport = @()
}
