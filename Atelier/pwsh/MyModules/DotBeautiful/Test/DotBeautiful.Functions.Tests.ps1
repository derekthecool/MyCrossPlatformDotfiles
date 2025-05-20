Describe 'DotBeautiful tests' {
    It 'No functions should be included' {
        $functions = Import-Module $PSScriptRoot/../DotBeautiful.psd1 -PassThru
        $functions.ExportedFunctions.Count | Should -Be 0
        $functions.ExportedAliases.Count | Should -Be 0
        $functions.ExportedCmdlets.Count | Should -Be 0
        $functions.ExportedCommands.Count | Should -Be 0
    }
}
