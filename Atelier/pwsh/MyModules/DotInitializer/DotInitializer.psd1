@{
    RootModule        = 'DotInitializer.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '9f16aa9b-62cf-46c9-bc6a-005c4eb08c6a'
    Author            = 'Derek Lomax'
    Description       = 'Module for initializing my cross platform array of cross platform computers'
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
    AliasesToExport   = @()
    FunctionsToExport = @(
        'Get-DotPackageList'
        'Get-DotPackages'
        'Install-DotPackages'
        'Update-DotPackages'
    )
}

