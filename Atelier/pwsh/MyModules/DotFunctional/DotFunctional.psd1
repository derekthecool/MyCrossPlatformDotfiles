@{
    RootModule        = 'DotFunctional.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '2cfbaa2f-a382-44de-8350-2d9619befb8d'
    Author            = 'Derek Lomax'
    Description       = 'Functional library for an easier time with map, filter, reduce, zip etc.'
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
        'Zip'
        'Reduce'
        'Sum'
        'Map'
        'Filter'
        'Flatten'
        'FlatMap'
        'Collect'
        'Take'
        'TakeWhile'
        'Skip'
        'SkipWhile'
        'Reverse'
        'GroupBy'
        'First'
        'Find'
        'Last'
        'Head'
        'Tail'
        'Fold'
        'Count'
        'Range'
    )
    FunctionsToExport = @(
        'Format-Pairs'
        'Reduce-Object'
        'Map-Object'
        'Filter-Object'
        'Flatten-Object'
        'FlatMap-Object'
        'Take-Object'
        'Take-WhileObject'
        'Skip-Object'
        'Skip-WhileObject'
        'Reverse-Object'
        'Group-ObjectBy'
        'Confirm-AnyObject'
        'Confirm-AllObject'
        'Select-FirstObject'
        'Select-LastObject'
        'Select-HeadObject'
        'Select-TailObject'
        'Fold-Object'
        'Count-ObjectWhere'
        'Initialize-Sequence'
    )
}
