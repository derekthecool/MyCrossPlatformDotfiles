@{
    RootModule        = 'DotAdventOfCode.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'c72bdc6f-2345-4895-babc-eb2bc8b79a1e'
    Author            = 'Derek Lomax'
    Description       = 'Helper functions for working with Advent of Code programming challenges. This module does not include any solutions to questions, just helper functions.'
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
        'aoc'
    )
    FunctionsToExport = @(
        'Get-AdventOfCodeData'
    )
}
