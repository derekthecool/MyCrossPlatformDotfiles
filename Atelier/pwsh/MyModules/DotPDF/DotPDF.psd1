@{
    RootModule        = 'DotPDF.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '8dbada96-3861-4b21-a3cb-478bb5b3c2d6'
    Author            = 'Derek Lomax'
    Description       = 'Functions to make working with PDFs easier'
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
        'gpi'
    )
    FunctionsToExport = @(
        'Get-PdfInfo'
    )
}

