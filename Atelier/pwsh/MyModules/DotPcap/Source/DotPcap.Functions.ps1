<#
    .SYNOPSIS
    pcap/pcapng packet analysis helper

    .DESCRIPTION
    Use tshark to parse pcap files as json, then verse to rich powershell objects

    .PARAMETER PcapPath
    Path to the input pcap/pcapng file

    .EXAMPLE
    PS> Add-Extension -name "File"
#>
function Read-Pcap
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$PcapPath
    )

    if(-not $(Get-Command tshark -ErrorAction SilentlyContinue))
    {
        Write-Error "The command [tshark] not found, cannot continue program"
        return
    }

    if(-not (Test-Path $PcapPath))
    {
        Write-Error "The input file $PcapPath is not found"
        return
    }

    $tshark_json = & tshark -T json --no-duplicate-keys --read-file "$PcapPath"
    $tshark_json | ConvertFrom-Json -Depth 100 | Select-Object -ExpandProperty _source | Select-Object -ExpandProperty layers
}
