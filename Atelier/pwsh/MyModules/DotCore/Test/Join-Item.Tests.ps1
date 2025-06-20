BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
    $items = 1 .. 5 | ForEach-Object { [PSCustomObject]@{Index = $_; Sum = $_ * 2 } }
}

Describe 'DotCore tests' {
    It 'Function Join-Item default separator' {
        $items | Join-Item -Property Sum | Should -Be '2 4 6 8 10'
    }

    It 'Function Join-Item custom separator' {
        $items | Join-Item ',' -Property Sum | Should -Be '2,4,6,8,10'
    }
}
