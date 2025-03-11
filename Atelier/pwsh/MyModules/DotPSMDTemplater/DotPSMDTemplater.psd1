@{
    RootModule        = 'DotPSMDTemplater.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '3c51f361-f9f6-4076-bbb3-5832f040ca3d'
    Author            = 'Derek Lomax'
    Description       = 'Module to manage PSModuleDevelopment custom templates'
    PowerShellVersion = '7.4'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''
    CmdletsToExport   = @()
    AliasesToExport   = @()
    # For maximum lazy load module performance list every function here.
    # Do not use '*', mainly because it pwsh will not autoload the module for unlisted functions.
    FunctionsToExport = @(
        'Get-DotPSMDTemplate'
        'Update-DotPSMDTemplate'
    )
}

