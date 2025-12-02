@{
    RootModule        = 'DotTUI.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'fede9069-a91b-497b-8d2a-19d5bc884e6a'
    Author            = 'Derek Lomax'
    Description       = 'Collection of TUIs for dotfiles'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    # AliasesToExport   = @(
    #     ''
    # )
    FunctionsToExport = @(
        'Show-DotTUI'
        'Get-DevEnvironmentInfo'
    )
}

