<#
    .SYNOPSIS
    Get the bytes for a pcap file header

    .DESCRIPTION
    This function gets the bytes for the pcap file header following the spec found
    here https://wiki.wireshark.org/Development/LibpcapFileFormat

    .OUTPUTS
    byte[]
#>
function Get-PcapFileHeader
{
    $header = New-Object byte[] 24

    # Magic number (0xa1b2c3d4)
    $header[0] = 0xd4
    $header[1] = 0xc3
    $header[2] = 0xb2
    $header[3] = 0xa1

    # Version major = 2
    $header[4] = 0x02
    $header[5] = 0x00

    # Version minor = 4
    $header[6] = 0x04
    $header[7] = 0x00

    # Thiszone (GMT to local correction) = 0
    $header[8] = 0x00
    $header[9] = 0x00
    $header[10] = 0x00
    $header[11] = 0x00

    # Sigfigs = 0
    $header[12] = 0x00
    $header[13] = 0x00
    $header[14] = 0x00
    $header[15] = 0x00

    # Snaplen = 65535 (max bytes per packet captured)
    $header[16] = 0xff
    $header[17] = 0xff
    $header[18] = 0x00
    $header[19] = 0x00

    # Network = 101 (LINKTYPE_RAW)
    $header[20] = 0x65
    $header[21] = 0x00
    $header[22] = 0x00
    $header[23] = 0x00

    return $header
}


<#
    .SYNOPSIS
    Returns a 16-byte PCAP packet header as a byte array.
    
    .PARAMETER Timestamp
    A [datetime] object representing the packet capture time.

    .PARAMETER CapturedLength
    Number of bytes of the packet actually captured (usually p->tot_len).

    .PARAMETER OriginalLength
    Actual length of the packet on the wire (usually same as CapturedLength for full capture).

    .OUTPUTS
    byte[]
    #>
function Get-PcapPacketHeader
{

    param(
        [Parameter()]
        [datetime]$Timestamp,

        [Parameter(Mandatory)]
        [int]$CapturedLength,

        [Parameter(Mandatory)]
        [int]$OriginalLength
    )

    $header = New-Object byte[] 16

    # Convert timestamp to seconds and microseconds
    $epoch = [datetime]"1970-01-01T00:00:00Z"
    $ts = $Timestamp.ToUniversalTime() - $epoch
    $ts_sec = [int][math]::Floor($ts.TotalSeconds)
    $ts_usec = [int](($ts.TotalSeconds - $ts_sec) * 1e6)

    # Helper to convert 32-bit int to little-endian bytes
    function ToLEBytes32([int]$val)
    {
        return [BitConverter]::GetBytes([UInt32]$val)
    }

    Write-Verbose "ts_sec: $ts_sec"
    Write-Verbose "ts_usec: $ts_usec"

    # Write fields
    [Array]::Copy((ToLEBytes32 $ts_sec), 0, $header, 0, 4)
    [Array]::Copy((ToLEBytes32 $ts_usec), 0, $header, 4, 4)
    [Array]::Copy((ToLEBytes32 $CapturedLength), 0, $header, 8, 4)
    [Array]::Copy((ToLEBytes32 $OriginalLength), 0, $header, 12, 4)

    return $header
}

function Format-PcapPacket
{
    param (
        [Parameter(ValueFromPipeline)]
        [byte[]]$Bytes
    )
    begin
    {
        $byteArray = @()
        Get-PcapPacketHeader -Timestamp (Get-Date) -CapturedLength ($Bytes.Length) -OriginalLength ($Bytes.Length)
    }
    process
    {
        $byteArray += $Bytes
    }
    end
    {
        $byteArray
    }
}

function Format-Pcap
{
    param (
        [Parameter(ValueFromPipeline)]
        [byte[]]$Bytes
    )
    begin
    {
        $byteArray = @()
        Get-PcapFileHeader
    }
    process
    {
        $byteArray += $Bytes
    }
    end
    {
        # TODO: (Derek Lomax) 12/12/2025 10:11:01 AM, obviously this really only supports a single packet
        $byteArray | Format-PcapPacket
    }
}
