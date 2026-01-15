@{
    RootModule        = 'DotModulator.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '69a0edd4-375b-4537-8666-17364863f695'
    Author            = 'Derek Lomax'
    Description       = 'Module helper functions'
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
        'fps'
    )
    FunctionsToExport = @(
        'Format-PowershellScriptFile'
        'Get-PowershellScriptFileAstDetails'
        'Get-PowershellAst'
    )
}
