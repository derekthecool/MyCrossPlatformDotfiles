@{
    RootModule        = 'DotPcap.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '8b1d6929-c04d-4713-9135-888800ef219c'
    Author            = 'Derek Lomax'
    Description       = 'Simple powershell pcap helper functions'
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
        'Read-Pcap'
        'Get-PcapFields'
        'Get-PcapTcpStreams'
        'Split-Pcap'
        'Split-PcapMqtt'
        'Get-PcapSummary'
    )
}

