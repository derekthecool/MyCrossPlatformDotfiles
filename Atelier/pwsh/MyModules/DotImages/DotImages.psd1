@{
    RootModule        = 'DotImages.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a7f3d8e2-5a4c-4f8e-9b1c-3d2e8f9a1b5c'
    Author            = 'Derek Lomax'
    Description       = 'Functions for extracting metadata from image and video files using exiftool'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'exif', 'metadata', 'image', 'exiftool')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @('gim')
    FunctionsToExport = @(
        'Get-ImageMetaData'
    )
}
