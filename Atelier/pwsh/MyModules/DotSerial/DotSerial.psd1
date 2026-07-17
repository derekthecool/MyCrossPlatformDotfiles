@{
    RootModule        = 'DotSerial.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'fbb9178d-5b83-4052-8fc4-c37a4c706e35'
    Author            = 'Derek Lomax'
    Description       = 'Serial port discovery helpers (cross-platform via pyserial)'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'serial', 'pyserial')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @('ports')
    FunctionsToExport = @(
        'Get-SerialPort'
    )
}
