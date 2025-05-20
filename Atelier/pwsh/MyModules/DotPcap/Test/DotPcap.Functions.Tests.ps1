BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPcap tests' {
    It 'Function Read-Pcap works' {
        $module = Import-Module $PSScriptRoot/../*.psd1 -Force -PassThru
        $module.ExportedFunctions.Count | Should -BeGreaterOrEqual 1
    }
}
