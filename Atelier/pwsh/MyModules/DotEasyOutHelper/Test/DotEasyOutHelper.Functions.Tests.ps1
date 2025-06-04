BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotEasyOutHelper tests' {
    It 'Basic alias check' {
        (Get-Command easy).Definition | Should -Be 'Use-EasyOut'
    }
}
