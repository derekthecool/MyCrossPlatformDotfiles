@{
    RootModule        = 'DotPcap.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '889fed45-0fbe-4461-9b74-72b9ca52b3aa'
    Author            = 'Derek Lomax'
    Description       = 'Read pcap files with powershell!'
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
        'Read-Pcap'
    )
    AliasesToExport   = @()
    FunctionsToExport = @()
}
