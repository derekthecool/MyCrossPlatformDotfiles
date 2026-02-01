BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotPDF tests' {
    It 'Function Get-PdfInfo works' {
        Get-Command Get-PdfInfo | Should -Be -Not $null
    }
}
