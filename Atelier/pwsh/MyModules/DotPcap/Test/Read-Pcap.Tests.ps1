BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPcap tests' {
    It 'Function Read-Pcap works' -Skip:($env:CI -ne '') {
        $file = "$PSScriptRoot/../ExamplePcap/200722_tcp_anon.pcapng"
        if([System.IO.File]::Exists($file))
        {
            return
        }

        $result = Read-Pcap -Path $file
        $result.Length | Should -Be 35
        $result[0].HardwareAddress | Should -Be 'ECF4BB96120E'
    }
}
