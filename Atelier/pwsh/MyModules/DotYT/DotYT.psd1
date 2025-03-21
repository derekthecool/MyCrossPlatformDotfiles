@{
    RootModule        = 'DotYT.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'eb74faa9-af67-4001-b672-acd52c8fb357'
    Author            = 'Derek Lomax'
    Description       = 'Functions for YT'
    PowerShellVersion = '7.4'
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
        'Find-YTData'
    )
    AliasesToExport   = @()
    FunctionsToExport = @()
}
