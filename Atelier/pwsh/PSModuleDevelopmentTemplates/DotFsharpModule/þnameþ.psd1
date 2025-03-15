@{
    RootModule        = 'þnameþ.psm1'
    ModuleVersion = '0.1.0'
    GUID              = 'þ!guid!þ'
    Author            = 'Derek Lomax'
    Description       = 'þDescriptionþ'
    PowerShellVersion = '7.4'
    PrivateData = @{
        PSData = @{
            Tags = @('dots', 'binary_module', 'compile_on_import')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.
    # This binary module will compile if dlls don't exist on module import!!!

    CmdletsToExport = @(
        'þverbþ-þnounþ'
    )
    AliasesToExport = @()
    FunctionsToExport = @()
}
