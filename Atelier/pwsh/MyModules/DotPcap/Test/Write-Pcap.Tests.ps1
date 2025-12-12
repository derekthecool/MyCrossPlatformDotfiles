BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1
}

Describe 'Header tests' {
    It '24 File header bytes should be exact' {
        Get-PcapFileHeader | Should -BeExactly 212, 195, 178, 161, 2, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 0, 0, 101, 0, 0, 0
    }

    It 'Packet header bytes for given date and length should match' { 
        $bytes = Get-PcapPacketHeader -Timestamp (Get-Date -Day 1 -Month 11 -Year 2025 -Hour 1 -Minute 5 -Second 7 -Millisecond 50) -CapturedLength 45 -OriginalLength 45
        $bytes | Should -BeExactly 147, 19, 6, 105, 80, 195, 0, 0, 45, 0, 0, 0, 45, 0, 0, 0
    }
}

Describe 'tshark parsing tests' -Skip:([bool](!(Get-Command tshark -ErrorAction SilentlyContinue))) {
    <#
    This packet is taken from this device hex dump
    1222: 2025-12-12 I (14:31:14.988) IP4TEST: 0x3c45a502   45 00 00 28 45 b2 40 00  fb 06 11 ef 0a d8 0b df  |E..(E.@.........|
    1223: 2025-12-12 I (14:31:14.988) IP4TEST: 0x3c45a512   0a 64 07 14 07 5b fc c5  6e 7f 53 a8 92 6f 11 95  |.d...[..n.S..o..|
    1224: 2025-12-12 I (14:31:14.988) IP4TEST: 0x3c45a522   50 10 13 5d 09 fc 00 00                           |P..]....|

    I used this command to collect the bytes and format properly to get my byte array
    which checks the system clipboard and extracts and formats the bytes
    [Convert]::FromHexString($(clipped -MatchFilter '^[0-9a-f]{2}$' | Join-String -Separator '')) | Join-String -Separator ', ' | Set-Clipboard
    #>
    It 'tshark can successfully parse the assembled pcap stream' { 
        $bytes = [byte[]]69, 0, 0, 40, 69, 178, 64, 0, 251, 6, 17, 239, 10, 216, 11, 223, 10, 100, 7, 20, 7, 91, 252, 197, 110, 127, 83, 168, 146, 111, 17, 149, 80, 16, 19, 93, 9, 252, 0, 0
        $pcapBytes = $bytes | Format-Pcap

        # Verify proper length of data + headers
        $expectedLength = $bytes.Length + 24 + 16
        $pcapBytes | Should -HaveCount $expectedLength

        # Use tshark to attempt to parse the pcap bytes
        # powershell does support bytes through pipeline to native applications
        $tsharkResult = $pcapBytes | tshark -r -
        $LASTEXITCODE | Should -Be 0
        # $tsharkResult | Should -Not -Match 'Malformed Packet'
    }
}
