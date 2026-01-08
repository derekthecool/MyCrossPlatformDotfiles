<#
    .SYNOPSIS
    pcap/pcapng packet analysis helper

    .DESCRIPTION
    Use tshark to parse pcap files as json, then verse to rich powershell objects

    .PARAMETER Path
    Path to the input pcap/pcapng file

    .EXAMPLE
    PS> Add-Extension -name "File"
#>
function Read-Pcap
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path
    )

    process
    {
        $tshark_json = & tshark -T json --no-duplicate-keys --read-file "$Path"

        # Clean up the json
        $tshark_json = $tshark_json -replace '"\w+\.', '"'

        # Now parse the json and select important items
        $tshark_json |
            ConvertFrom-Json -Depth 100 |
            Select-Object -ExpandProperty _source |
            Select-Object -ExpandProperty layers |
            ForEach-Object {
                [PSCustomObject]@{
                    Data = $_
                    Time = [DateTime]::ParseExact(($_.frame.time_utc -replace '\.(\d{7})\d+','.$1'),"MMM dd, yyyy HH:mm:ss.fffffff 'UTC'",$null)
                    HighestProtocol = $_.PSObject.Properties | Select-Object -Last 1 -ExpandProperty Name
                }
            }
    }
}

function Find-Tshark
{
    if (-not $(Get-Command tshark -ErrorAction SilentlyContinue))
    {
        throw "The command [tshark] not found, cannot continue program"
    }
}


function Split-Pcap
{
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

function Get-PcapField
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path,
        [Parameter(Mandatory, Position = 0)]
        [string]$Field,
        [string]$DisplayFilter = ''
    )
    process
    {
        Write-Verbose "Processing Path: $Path, Field: $Field, DisplayFilter: $DisplayFilter"
        tshark -r "$Path" -d "tcp.port==1886-1888,mqtt" -T fields -e "$Field" --display-filter $DisplayFilter 2>$null |
            Where-Object { $_ } |
            Sort-Object -Unique
    }
}


function Get-PcapTcpStream
{
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path
    )
    process
    {
        $Path | Get-PcapField -Field 'tcp.stream'
    }
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
function Split-PcapMqtt
{
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path,
        [string]$ClientIdFilter = ".+"
    )
    begin
    {
        Write-Verbose "Begin parsing pcap files for mqtt data with ClientIdFilter: $ClientIdFilter"
        $script:allPaths = @()
    }
    process
    {
        $script:allPaths += $Path
    }

    end
    {
        $file_index = 0
        Write-Verbose "Processing $($script:allPaths.Length) files"
        $script:AllPaths | ForEach-Object {
            $CurrentPath = $_
            $client_ids = $CurrentPath |
                Get-PcapField -Field 'mqtt.clientid' |
                Where-Object { $_ -match $ClientIdFilter }

                if ($client_ids)
                {
                    Write-Verbose "$client_ids"
                } else
                {
                    Write-Verbose "No mqtt client ids matching pattern ($ClientIdFilter) were found in file $((Get-ChildItem $CurrentPath).Name)"
                }

                $FilesPercentComplete = [Math]::Floor(($file_index / $script:allPaths.Length) * 100)
                Write-Progress -Id 1 -Activity $MyInvocation.MyCommand.Name -Status "File Percent complete: $FilesPercentComplete, Current Item: $((Get-ChildItem $CurrentPath).Name)" -PercentComplete $FilesPercentComplete
                $client_count = $client_ids.Length
                $count = 0
                $client_ids |
                    ForEach-Object { 
                        $count++
                        $streams = Get-PcapField -Path $CurrentPath -Field 'tcp.stream' -DisplayFilter "mqtt.clientid contains `"$_`"" | Join-String -Separator ','
                        $outputDirectory = "$([System.IO.Path]::GetFileNameWithoutExtension($CurrentPath))_parsed"
                        New-Item -ItemType Directory -ErrorAction SilentlyContinue $outputDirectory | Out-Null
                        tshark -r "$CurrentPath" -Y "tcp.stream in {$streams}" -w "$outputDirectory/mqtt_session_${_}.pcap" 2>$null
                        $PercentComplete = $([Math]::Floor(($count / $client_count) * 100))
                        Write-Progress -Id 2 -Activity $MyInvocation.MyCommand.Name -Status "Percent complete: $PercentComplete, Current Item: $_" -PercentComplete $PercentComplete
                    }
                    $file_index++
                }
            }
        }

        function Get-PcapSummary
        {
            param (
                [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
                [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
                [string]$Path
            )
            process
            {
                $summary = capinfos -T -m $Path | ConvertFrom-Csv
                if (-not $? -or $LASTEXITCODE -ne 0)
                {
                    # TODO: (Derek Lomax) 10/13/2025 4:38:46 PM, handle the error where pcap file last packet is corrupted. This entire command will fail.
                    # this command might help to fix the error
                    # editcap -r input.pcap trimmed.pcap 0 -2  # drop last 2 packets, for example
                    throw "capinfos failure"
                }
                $protocols = tshark -T fields -e _ws.col.Protocol -r "$Path" | Sort-Object -Unique
                if (-not $? -or $LASTEXITCODE -ne 0)
                {
                    throw "tshark failure"
                }

                $summary | Add-Member -MemberType NoteProperty -Name Protocols -Value $protocols
                $summary
            }
        }
