@{
    RootModule        = 'DotSdk.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '8322482c-8cf2-49c5-9c6f-018ff2d0ca9b'
    Author            = 'Derek Lomax'
    Description       = 'SDK and compiled-language toolchain helpers (dotnet, Visual Studio, gcc)'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'dotnet', 'sdk', 'gcc', 'visual-studio', 'msbuild')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @(
        'dotnet-GetOutdated'
    )
    FunctionsToExport = @(
        'Get-DotnetOutdatedPackage'
        'Start-VSCompiler'
    )
}
