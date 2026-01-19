@{
    RootModule        = 'Dot.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '2bbabdf4-23c8-4ae2-be9c-8192842a3c10'
    Author            = 'Derek Lomax'
    Description       = 'Core function for bare repository management. Quick loading is essential.'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''
    CmdletsToExport   = @()
    AliasesToExport   = @(
        'dotgit'
    )
    # For maximum lazy load module performance list every function here.
    # Do not use '*', mainly because it pwsh will not autoload the module for unlisted functions.
    FunctionsToExport = @(
        'dot'
        'Initialize-Dotfiles'
        'Clone-GitRepository'
        'Get-NeovimConfigurationDirectory'
        'Get-NeovimConfiguration'
        'Get-WeztermConfigurationDirectory'
        'Get-WeztermConfiguration'
        'Get-PloverConfigurationDirectory'
        'Get-PloverConfiguration'
        'Get-ExercismConfigurationDirectory'
        'Get-ExercismConfiguration'
        'Get-AwesomeWmWidgets'
        'Get-AllConfigurations'
        'dots'
    )
}
