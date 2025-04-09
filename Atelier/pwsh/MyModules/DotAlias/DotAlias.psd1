@{
    RootModule        = 'DotAlias.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'd607bab7-58b8-4fa9-9ade-1ca1ef16bae7'
    Author            = 'Derek Lomax'
    Description       = 'Collection of powershell aliases which will be lazy loaded'
    PowerShellVersion = '7.4'
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
        'ls'
        'cp'
        'sort'
        'sleep'
        'ps'
        'rm'
        'kill'
        'cat'
        'clear'
        'mv'
        'tee'
        'cd'
    )

    # Naughty aliases! (to lazy load as expected they need to be a function)
    FunctionsToExport = @(
        'diff'
        'rmdir'
    )
}
