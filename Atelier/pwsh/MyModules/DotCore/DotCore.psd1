@{
    RootModule         = 'DotCore.psm1'
    ModuleVersion      = '0.1.0'
    GUID               = 'c188bcf0-9fba-460d-befd-001c5ff45abf'
    Author             = 'Derek Lomax'
    Description        = 'Module for simple, core powershell utility functions'
    PrivateData        = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    RequiredAssemblies = @('SharpCompress.dll')
    VariablesToExport  = ''
    CmdletsToExport    = @()
    AliasesToExport    = @(
        'join'
    )
    FunctionsToExport  = @(
        'Join-Item'
        'ConvertFrom-Xml'
        'Find-DuplicateFile'
        'Expand-Everything'
    )
}
