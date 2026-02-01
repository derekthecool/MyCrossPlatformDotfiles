@{
    RootModule         = 'DotTUI.psm1'
    ModuleVersion      = '0.1.0'
    GUID               = 'fede9069-a91b-497b-8d2a-19d5bc884e6a'
    Author             = 'Derek Lomax'
    Description        = 'Collection of TUIs for dotfiles'
    PrivateData        = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    # Terminal.GUI v2 - caused lots of trouble and did not work!: https://www.nuget.org/packages/Terminal.Gui/2.0.0-alpha.4111
    # Terminal.GUI v1 - works! I'm using netstandard2.1 https://www.nuget.org/packages/Terminal.Gui/1.19.0
    # NStack.dll is also required
    # Super helpful guide: https://blog.ironmansoftware.com/tui-powershell/
    RequiredAssemblies = @('NStack.dll', 'Terminal.Gui.netstandard2.1_v1.19.0.dll')
    VariablesToExport  = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport    = @()
    # AliasesToExport   = @(
    #     ''
    # )
    FunctionsToExport  = @(
        'Show-DotTUI'
        'Get-DevEnvironmentInfo'

        # Terminal.GUI functions
        'Show-TerminalGuiV1Example'
        'Show-TerminalGuiV2Example'
    )
}
