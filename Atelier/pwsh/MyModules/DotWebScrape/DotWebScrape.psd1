@{
    RootModule        = 'DotWebScrape.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '5705eff0-ddf3-48ff-a2e6-aa174404edb3'
    Author            = 'Derek Lomax'
    Description       = 'Module for simple web scraping tasks'
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
        'scrape'
        'text'
    )
    FunctionsToExport = @(
        'Get-Site'
        'Get-SiteText'
    )
}

