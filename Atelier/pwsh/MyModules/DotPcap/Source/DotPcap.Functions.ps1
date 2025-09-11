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


    if (-not (Test-Path $PcapPath))
    {
        Write-Error "The input file $PcapPath is not found"
        return
    }

    $tshark_json = & tshark -T json --no-duplicate-keys --read-file "$PcapPath"
    $tshark_json | ConvertFrom-Json -Depth 100 | Select-Object -ExpandProperty _source | Select-Object -ExpandProperty layers
}

function Find-Tshark {
    if (-not $(Get-Command tshark -ErrorAction SilentlyContinue))
    {
        throw "The command [tshark] not found, cannot continue program"
        return
    }
}


function Split-Pcap {
    
    param (
      [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
      [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
      [string]$Path
    )
    

# for stream in $(tshark -r "$file" -T fields -e tcp.stream | sort -n | uniq); do
#     tshark -r "$file" -Y "tcp.stream in {$stream}" # -w "$file.stream_$stream.pcap"
# done

 tshark -r MqttTcpdumpCapture_2025-09-10_1757540368.pcap -T fields -e mqtt.clientid | Sort-Object -Unique | Where-Object { $_ } | ForEach-Object { tshark -r MqttTcpdumpCapture_2025-09-10_1757540368.pcap -T fields -e tcp.stream --display-filter "mqtt contains `"$_`"" }

}

function Get-PcapFields {
param (
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Field,
    [string]$DisplayFilter = ''
)
  process
  {
    tshark -r "$Path" -T fields -e "$Field" --display-filter $DisplayFilter 2>$null | Where-Object { $_ } | Sort-Object -Unique
  }
}


function Get-PcapTcpStreams {
param (
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$Path
)
    $Path | Get-PcapFields -Field 'tcp.stream'
}

<#
    .SYNOPSIS
    Split pcap network captures into multiple pcaps grouped by mqtt client id

    .DESCRIPTION
    Using tshark find all mqtt client ids and associated tcp streams and group them into new pcap files

    .PARAMETER Path
    Path to the input pcap/pcapng file

    .PARAMETER ClientIdFilter
    Regex to filter client ids to keep, ".+" by default

    .EXAMPLE
    # Basic example with a ClientIdFilter set to 6 letter long client ids
    PS> Split-PcapMqtt -Path .\MqttTcpdumpCapture_2025-06-12_1749744827.pcap -ClientIdFilter '^\w{6}$'
#>
function Split-PcapMqtt {
param (
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$Path,
    [string]$ClientIdFilter = ".+",
    [string]$OutputDirectory = "$([System.IO.Path]::GetFileNameWithoutExtension($Path))_parsed"
)
  New-Item -ItemType Directory -ErrorAction SilentlyContinue $OutputDirectory
  $client_ids = $Path | Get-PcapFields -Field 'mqtt.clientid' | Where-Object { $_ -match $ClientIdFilter }
  $client_count = $client_ids.Length
  $count = 0
  $client_ids | ForEach-Object { 
    $count++
    $streams = Get-PcapFields -Path $Path -Field 'tcp.stream' -DisplayFilter "mqtt.clientid contains `"$_`"" | Join-String -Separator ','
    tshark -r "$Path" -Y "tcp.stream in {$streams}" -w "$OutputDirectory/mqtt_session_${_}.pcap" 2>$null
    $PercentComplete = $([Math]::Floor(($count / $client_count) * 100))
    Write-Progress -Activity $MyInvocation.MyCommand.Name -Status "Percent complete: $PercentComplete, Current Item: $_" -PercentComplete $PercentComplete
  }

}
