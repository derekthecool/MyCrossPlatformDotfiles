@{
    RootModule        = 'DotCompleter.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b84d2790-0b36-4082-97e0-32c399b925a9'
    Author            = 'Derek Lomax'
    Description       = 'Argument completer registrations for orphan CLI tools that have no dedicated Dot* module'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'completion', 'tab-completion', 'argument-completer')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @()
    FunctionsToExport = @(
        'Get-GeneralCompletion'
    )
}
