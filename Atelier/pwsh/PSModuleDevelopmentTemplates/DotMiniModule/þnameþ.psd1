@{
    RootModule = 'þnameþ.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'þ!guid!þ'
    Author = 'Derek Lomax'
    Description = 'þDescriptionþ'
    PowerShellVersion = '7.4'
    PrivateData = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''
    CmdletsToExport = @()
    AliasesToExport = @()
    # For maximum lazy load module performance list every function here.
    # Do not use '*', mainly because it pwsh will not autoload the module for unlisted functions.
    FunctionsToExport = @(
        'þFirst-Functionþ'
    )
}

