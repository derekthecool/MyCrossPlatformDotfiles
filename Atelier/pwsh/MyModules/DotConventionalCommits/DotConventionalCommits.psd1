@{
    RootModule        = 'DotConventionalCommits.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a989056c-1729-4431-a082-b87c21ccca3b'
    Author            = 'Derek Lomax'
    Description       = 'Helper functions to use conventional commits in my workflows'
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
        'Get-ConventionalCommitValues'
        'Select-ConventionalCommitValue'
        'Select-ConventionalCommitFileScope'
    )
}

