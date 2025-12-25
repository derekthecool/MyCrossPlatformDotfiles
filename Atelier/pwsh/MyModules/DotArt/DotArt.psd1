@{
    RootModule        = 'DotArt.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'f64b4094-d7a5-410f-b273-c1f0b7796418'
    Author            = 'Derek Lomax'
    Description       = 'Fun module for showing ASCII art images and animations. Some written by me, and sourcing some written by others.'
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
        'sct'
    )
    FunctionsToExport = @(
        'Show-ChristmasTree'
    )
}

