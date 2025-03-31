# Module manifest for module 'Dots'
# Generated by: Derek Lomax
# Generated on: 4/3/2024

@{
    # Script module or binary module file associated with this manifest.
    RootModule        = './Dots.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '463ce966-d7ad-4cde-9874-cf133833f073'

    # Author of this module
    Author            = 'Derek Lomax'

    # Company or vendor of this module
    CompanyName       = 'Unknown'

    # Copyright statement for this module
    Copyright         = '(c) Derek Lomax. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Powerful dot file collection module'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.4'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry,
    # use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Functions from ./DotfileManagement.ps1
        'dots'
        'Clone-GitRepository'
        'Add-MasonToolsToPath'
        'Get-AllConfigurations'

        'Get-AdventOfCodeData'

        # Lastly, load everything else so every function is available after the first Import-Module
        '*'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry,
    # use an empty array if there are no cmdlets to export.
    CmdletsToExport   = '*'

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry,
    # use an empty array if there are no aliases to export.
    AliasesToExport   = @(
        'ports'
        '*'
    )

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # # Process this in ./Dots.psm1 instead because I want the items I set to be the default formatviews
    # # Getting my items to become the default views requires running Update-FormatData -PrependPath ./Dots.format.ps1xml
    # # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @(
    #     './Dots.format.ps1xml'
    # )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Supported PSEditions
    # CompatiblePSEditions = @()
}
