BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'Fold-Object' {
    It 'Fold-Object exists' {
        Get-Command Fold-Object | Should -Be -Not $null
    }

    It 'Fold alias exists' {
        Get-Alias Fold | Should -Be -Not $null
    }

    It 'Fold-Object with initial value reduces correctly' {
        1 .. 5 | Fold-Object { $args[0] + $args[1] } -InitialValue 10 | Should -Be 25
    }

    It 'Fold-Object with multiplication' {
        1 .. 4 | Fold-Object { $args[0] * $args[1] } -InitialValue 1 | Should -Be 24
    }

    It 'Fold-Object with string concatenation' {
        @('a', 'b', 'c') | Fold-Object { $args[0] + $args[1] } -InitialValue '' | Should -Be 'abc'
    }

    It 'Fold works as alias' {
        1 .. 3 | Fold { $args[0] * $args[1] } -InitialValue 2 | Should -Be 12
    }
}

Describe 'Count-ObjectWhere' {
    It 'Count-ObjectWhere exists' {
        Get-Command Count-ObjectWhere | Should -Be -Not $null
    }

    It 'Count alias exists' {
        Get-Alias Count | Should -Be -Not $null
    }

    It 'Count-ObjectWhere counts matching elements' {
        1 .. 10 | Count-ObjectWhere { $_ % 2 -eq 0 } | Should -Be 5
    }

    It 'Count-ObjectWhere counts all when no predicate' {
        1 .. 5 | Count-ObjectWhere | Should -Be 5
    }

    It 'Count-ObjectWhere returns zero for no matches' {
        1 .. 5 | Count-ObjectWhere { $_ -gt 10 } | Should -Be 0
    }

    It 'Count works as alias' {
        1 .. 10 | Count { $_ -lt 5 } | Should -Be 4
    }
}

Describe 'Initialize-Sequence' {
    It 'Initialize-Sequence exists' {
        Get-Command Initialize-Sequence | Should -Be -Not $null
    }

    It 'Range alias exists' {
        Get-Alias Range | Should -Be -Not $null
    }

    It 'Range with single argument generates 1 to N' {
        Range 5 | Should -Be @(1, 2, 3, 4, 5)
    }

    It 'Range with start and end' {
        Range 1 5 | Should -Be @(1, 2, 3, 4, 5)
    }

    It 'Range with step' {
        Range 1 10 2 | Should -Be @(1, 3, 5, 7, 9)
    }

    It 'Range counts down with reverse bounds' {
        Range 5 1 -1 | Should -Be @(5, 4, 3, 2, 1)
    }

    It 'Range with explicit step parameter name' {
        Range 1 5 -Step 2 | Should -Be @(1, 3, 5)
    }

    It 'Initialize-Sequence -Start -End generates simple range' {
        Initialize-Sequence -Start 1 -End 5 | Should -Be @(1, 2, 3, 4, 5)
    }

    It 'Initialize-Sequence with step parameter name' {
        Initialize-Sequence -Start 1 -End 10 -Step 2 | Should -Be @(1, 3, 5, 7, 9)
    }
}
