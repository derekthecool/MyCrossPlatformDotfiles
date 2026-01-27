BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPSMDTemplater tests' {
    It 'Function Get-DotPSMDTemplate is null initially' {
        Remove-DotPSMDTemplate
        Get-DotPSMDTemplate | Should -Be $null
    }

    It 'Function Get-DotPSMDTemplate is not null after loading my templates' {
        Update-DotPSMDTemplate -Path "./Atelier/pwsh/PSModuleDevelopmentTemplates/"
        Get-DotPSMDTemplate | Should -Be -Not $null
    }
}
