BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPcap tests' {
    It 'Function Read-Pcap works' {
        Read-Pcap | Should -Be -Not $null
    }
}
