BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPcap tests' {
    It 'Function Read-Pcap works' {
        $file = "$PSScriptRoot/../ExamplePcap/200722_tcp_anon.pcapng"
        $result = Read-Pcap -Path $file
        $result.Length | Should -Be 35
        $result[0].HardwareAddress | Should -Be 'ECF4BB96120E'
    }
}
