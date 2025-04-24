BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPcap tests' {
    It 'Function Read-Pcap works' {
        Read-Pcap 23 | Should -Be -Not $null
    }
}
