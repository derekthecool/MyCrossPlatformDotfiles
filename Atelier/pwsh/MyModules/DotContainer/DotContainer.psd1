@{
    RootModule        = 'DotContainer.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '738772b6-c79b-46dd-a0cd-97d90f24cecb'
    Author            = 'Derek Lomax'
    Description       = 'Helper functions for container applications (podman/docker)'
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
        'c'
        'container'
    )
    FunctionsToExport = @(
        'Get-ContainerRunner'
        'Use-Container'
        'Get-ComposeContainerRunner'
        'Use-ComposeContainer'
        'compose'
        'mmdc'
        'Use-PandocLatexMdToPdf'
        'Use-YTDLP'
    )
}
