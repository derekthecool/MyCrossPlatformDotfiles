BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'Format-Pairs' {
    It 'Function Format-Pairs exists' {
        Get-Command Format-Pairs | Should -Be -Not $null
    }

    It 'Function Format-Pairs without reducing function creates an array of arrays' { 
        $array = @(1, 2, 3, 4, 5, 6)
        $array | Format-Pairs | Should -Be @(@(1, 2), @(2, 3), @(3, 4), @(4, 5), @(5, 6))
    }

    It 'Function Format-Pairs with reducing function correctly calculates values' { 
        $array = @(1, 2, 3, 4, 5, 6)
        $array | Format-Pairs -Operation { $args[0] + $args[1] } | Should -Be @(3, 5, 7, 9, 11)
    }
}

Describe 'Reduce-Object' {
    It 'Reduce-Object exists' {
        Get-Command Reduce-Object | Should -Be -Not $null
    }

    It 'Reduce-Object with no provided script block or initial value sums values' {
        1 .. 10 | Reduce-Object | Should -Be 55
    }
}

Describe 'Map-Object' {
    It 'Map-Object exists' {
        Get-Command Map-Object | Should -Be -Not $null
    }

    It 'Map alias exists' {
        Get-Alias Map | Should -Be -Not $null
    }

    It 'Map-Object transforms each element' {
        1 .. 5 | Map-Object { $_ * 2 } | Should -Be @(2, 4, 6, 8, 10)
    }

    It 'Map-Object with string transformation' {
        @('a', 'b', 'c') | Map-Object { $_.ToUpper() } | Should -Be @('A', 'B', 'C')
    }

    It 'Map-Object with complex objects' {
        $result = 1 .. 3 | Map-Object { [PSCustomObject]@{ Value = $_; Doubled = $_ * 2 } }
        @($result).Count | Should -Be 3
    }

    It 'Map-Object handles empty input' {
        @() | Map-Object { $_ * 2 } | Should -BeNullOrEmpty
    }

    It 'Map works as alias' {
        1 .. 3 | Map { $_ + 10 } | Should -Be @(11, 12, 13)
    }
}

Describe 'Filter-Object' {
    It 'Filter-Object exists' {
        Get-Command Filter-Object | Should -Be -Not $null
    }

    It 'Filter alias exists' {
        Get-Alias Filter | Should -Be -Not $null
    }

    It 'Filter-Object keeps matching elements' {
        1 .. 10 | Filter-Object { $_ % 2 -eq 0 } | Should -Be @(2, 4, 6, 8, 10)
    }

    It 'Filter-Object handles empty input' {
        @() | Filter-Object { $true } | Should -BeNullOrEmpty
    }

    It 'Filter-Object filters out all non-matching' {
        1 .. 5 | Filter-Object { $_ -gt 10 } | Should -BeNullOrEmpty
    }

    It 'Filter works as alias' {
        1 .. 5 | Filter { $_ -lt 3 } | Should -Be @(1, 2)
    }
}

Describe 'Flatten-Object' {
    It 'Flatten-Object exists' {
        Get-Command Flatten-Object | Should -Be -Not $null
    }

    It 'Flatten alias exists' {
        Get-Alias Flatten | Should -Be -Not $null
    }

    It 'Flatten-Object flattens nested arrays' {
        @(1, @(2, 3), 4) | Flatten-Object | Should -Be @(1, 2, 3, 4)
    }

    It 'Flatten-Object handles deeply nested arrays' {
        @(1, @(2, @(3, 4)), 5) | Flatten-Object | Should -Be @(1, 2, @(3, 4), 5)
    }

    It 'Flatten-Object handles empty arrays' {
        @(@(), 1, @()) | Flatten-Object | Should -Be @(1)
    }

    It 'Flatten works as alias' {
        @(1, @(2, 3)) | Flatten | Should -Be @(1, 2, 3)
    }
}

Describe 'FlatMap-Object' {
    It 'FlatMap-Object exists' {
        Get-Command FlatMap-Object | Should -Be -Not $null
    }

    It 'FlatMap alias exists' {
        Get-Alias FlatMap | Should -Be -Not $null
    }

    It 'Collect alias exists' {
        Get-Alias Collect | Should -Be -Not $null
    }

    It 'FlatMap-Object maps then flattens' {
        1 .. 3 | FlatMap-Object { $_; $_ * 2 } | Should -Be @(1, 2, 2, 4, 3, 6)
    }

    It 'FlatMap-Object with empty results' {
        1 .. 3 | FlatMap-Object { if ($_ -gt 2) { ,@($_) } } | Should -Be @(3)
    }
}

Describe 'Take-Object' {
    It 'Take-Object exists' {
        Get-Command Take-Object | Should -Be -Not $null
    }

    It 'Take alias exists' {
        Get-Alias Take | Should -Be -Not $null
    }

    It 'Take-Object takes first n elements' {
        1 .. 10 | Take-Object 3 | Should -Be @(1, 2, 3)
    }

    It 'Take-Object takes zero elements' {
        1 .. 5 | Take-Object 0 | Should -BeNullOrEmpty
    }

    It 'Take-Object takes more than available' {
        1 .. 3 | Take-Object 10 | Should -Be @(1, 2, 3)
    }

    It 'Take works as alias' {
        1 .. 5 | Take 2 | Should -Be @(1, 2)
    }
}

Describe 'Take-WhileObject' {
    It 'Take-WhileObject exists' {
        Get-Command Take-WhileObject | Should -Be -Not $null
    }

    It 'TakeWhile alias exists' {
        Get-Alias TakeWhile | Should -Be -Not $null
    }

    It 'Take-WhileObject takes while predicate true' {
        1 .. 10 | Take-WhileObject { $_ -lt 5 } | Should -Be @(1, 2, 3, 4)
    }

    It 'Take-WhileObject takes none if predicate false immediately' {
        1 .. 5 | Take-WhileObject { $_ -gt 10 } | Should -BeNullOrEmpty
    }

    It 'Take-WhileObject takes all if predicate always true' {
        1 .. 5 | Take-WhileObject { $true } | Should -Be @(1, 2, 3, 4, 5)
    }

    It 'TakeWhile works as alias' {
        1 .. 10 | TakeWhile { $_ -le 3 } | Should -Be @(1, 2, 3)
    }
}

Describe 'Skip-Object' {
    It 'Skip-Object exists' {
        Get-Command Skip-Object | Should -Be -Not $null
    }

    It 'Skip alias exists' {
        Get-Alias Skip | Should -Be -Not $null
    }

    It 'Skip-Object skips first n elements' {
        1 .. 10 | Skip-Object 3 | Should -Be @(4, 5, 6, 7, 8, 9, 10)
    }

    It 'Skip-Object skips zero elements' {
        1 .. 5 | Skip-Object 0 | Should -Be @(1, 2, 3, 4, 5)
    }

    It 'Skip-Object skips more than available' {
        1 .. 3 | Skip-Object 10 | Should -BeNullOrEmpty
    }

    It 'Skip works as alias' {
        1 .. 5 | Skip 2 | Should -Be @(3, 4, 5)
    }
}

Describe 'Skip-WhileObject' {
    It 'Skip-WhileObject exists' {
        Get-Command Skip-WhileObject | Should -Be -Not $null
    }

    It 'SkipWhile alias exists' {
        Get-Alias SkipWhile | Should -Be -Not $null
    }

    It 'Skip-WhileObject skips while predicate true' {
        1 .. 10 | Skip-WhileObject { $_ -lt 5 } | Should -Be @(5, 6, 7, 8, 9, 10)
    }

    It 'Skip-WhileObject skips none if predicate false immediately' {
        1 .. 5 | Skip-WhileObject { $_ -gt 10 } | Should -Be @(1, 2, 3, 4, 5)
    }

    It 'Skip-WhileObject skips all if predicate always true' {
        1 .. 5 | Skip-WhileObject { $true } | Should -BeNullOrEmpty
    }

    It 'SkipWhile works as alias' {
        1 .. 10 | SkipWhile { $_ -le 5 } | Should -Be @(6, 7, 8, 9, 10)
    }
}

Describe 'Reverse-Object' {
    It 'Reverse-Object exists' {
        Get-Command Reverse-Object | Should -Be -Not $null
    }

    It 'Reverse alias exists' {
        Get-Alias Reverse | Should -Be -Not $null
    }

    It 'Reverse-Object reverses collection' {
        1 .. 5 | Reverse-Object | Should -Be @(5, 4, 3, 2, 1)
    }

    It 'Reverse-Object handles single element' {
        1 | Reverse-Object | Should -Be @(1)
    }

    It 'Reverse-Object handles empty collection' {
        @() | Reverse-Object | Should -BeNullOrEmpty
    }

    It 'Reverse works as alias' {
        @(10, 20, 30) | Reverse | Should -Be @(30, 20, 10)
    }
}

Describe 'Group-ObjectBy' {
    It 'Group-ObjectBy exists' {
        Get-Command Group-ObjectBy | Should -Be -Not $null
    }

    It 'GroupBy alias exists' {
        Get-Alias GroupBy | Should -Be -Not $null
    }

    It 'Group-ObjectBy groups by key function' {
        $groups = 1 .. 6 | Group-ObjectBy { $_ % 2 }
        $groups.Count | Should -Be 2
    }

    It 'Group-ObjectBy groups strings by length' {
        $groups = @('a', 'bb', 'cc', 'dd') | Group-ObjectBy { $_.Length }
        $groups.Count | Should -Be 2
    }

    It 'GroupBy works as alias' {
        $groups = 1 .. 4 | GroupBy { $_ -gt 2 }
        $groups.Count | Should -Be 2
    }
}

Describe 'Confirm-AnyObject' {
    It 'Confirm-AnyObject exists' {
        Get-Command Confirm-AnyObject | Should -Be -Not $null
    }

    It 'Confirm-AnyObject returns true if any element matches' {
        1 .. 5 | Confirm-AnyObject { $_ -gt 3 } | Should -Be $true
    }

    It 'Confirm-AnyObject returns false if no element matches' {
        1 .. 5 | Confirm-AnyObject { $_ -gt 10 } | Should -Be $false
    }

    It 'Confirm-AnyObject returns true for any element without predicate' {
        1 .. 5 | Confirm-AnyObject | Should -Be $true
    }

    It 'Confirm-AnyObject returns false for empty collection' {
        @() | Confirm-AnyObject { $true } | Should -Be $false
    }
}

Describe 'Confirm-AllObject' {
    It 'Confirm-AllObject exists' {
        Get-Command Confirm-AllObject | Should -Be -Not $null
    }

    It 'Confirm-AllObject returns true if all elements match' {
        2, 4, 6, 8, 10 | Confirm-AllObject { $_ % 2 -eq 0 } | Should -Be $true
    }

    It 'Confirm-AllObject returns false if any element does not match' {
        1 .. 5 | Confirm-AllObject { $_ -gt 3 } | Should -Be $false
    }

    It 'Confirm-AllObject returns true for empty collection' {
        @() | Confirm-AllObject { $true } | Should -Be $true
    }
}

Describe 'Select-FirstObject' {
    It 'Select-FirstObject exists' {
        Get-Command Select-FirstObject | Should -Be -Not $null
    }

    It 'First alias exists' {
        Get-Alias First | Should -Be -Not $null
    }

    It 'Find alias exists' {
        Get-Alias Find | Should -Be -Not $null
    }

    It 'Select-FirstObject returns first element' {
        1 .. 5 | Select-FirstObject | Should -Be 1
    }

    It 'Select-FirstObject returns first matching element' {
        1 .. 10 | Select-FirstObject { $_ % 3 -eq 0 } | Should -Be 3
    }

    It 'Select-FirstObject returns null for empty collection' {
        @() | Select-FirstObject | Should -BeNullOrEmpty
    }

    It 'Select-FirstObject returns null when no match' {
        1 .. 5 | Select-FirstObject { $_ -gt 10 } | Should -BeNullOrEmpty
    }

    It 'First works as alias' {
        5, 10, 15 | First | Should -Be 5
    }

    It 'Find works as alias' {
        1 .. 10 | Find { $_ -gt 5 } | Should -Be 6
    }
}

Describe 'Select-LastObject' {
    It 'Select-LastObject exists' {
        Get-Command Select-LastObject | Should -Be -Not $null
    }

    It 'Last alias exists' {
        Get-Alias Last | Should -Be -Not $null
    }

    It 'Select-LastObject returns last element' {
        1 .. 5 | Select-LastObject | Should -Be 5
    }

    It 'Select-LastObject returns null for empty collection' {
        @() | Select-LastObject | Should -BeNullOrEmpty
    }

    It 'Last works as alias' {
        5, 10, 15 | Last | Should -Be 15
    }
}

Describe 'Select-HeadObject' {
    It 'Select-HeadObject exists' {
        Get-Command Select-HeadObject | Should -Be -Not $null
    }

    It 'Head alias exists' {
        Get-Alias Head | Should -Be -Not $null
    }

    It 'Select-HeadObject returns first element safely' {
        1 .. 5 | Select-HeadObject | Should -Be 1
    }

    It 'Select-HeadObject returns null for empty collection' {
        @() | Select-HeadObject | Should -BeNullOrEmpty
    }

    It 'Head works as alias' {
        @(42) | Head | Should -Be 42
    }
}

Describe 'Select-TailObject' {
    It 'Select-TailObject exists' {
        Get-Command Select-TailObject | Should -Be -Not $null
    }

    It 'Tail alias exists' {
        Get-Alias Tail | Should -Be -Not $null
    }

    It 'Select-TailObject returns all but first element' {
        1 .. 5 | Select-TailObject | Should -Be @(2, 3, 4, 5)
    }

    It 'Select-TailObject returns empty for single element' {
        1 | Select-TailObject | Should -BeNullOrEmpty
    }

    It 'Select-TailObject returns empty for empty collection' {
        @() | Select-TailObject | Should -BeNullOrEmpty
    }

    It 'Tail works as alias' {
        @(1, 2, 3) | Tail | Should -Be @(2, 3)
    }
}

