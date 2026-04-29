# https://blog.ironmansoftware.com/daily-powershell/powershell-linq/
# this could maybe be used, but it does not contain most of the Linq I want

function Format-Pairs
{
    [CmdletBinding()]
    [Alias("Zip")]
    param (
        [Parameter(ValueFromPipeline)]
        [object]$InputObject,

        [scriptblock]$Operation
    )

    begin
    {
        $index = 0
    }

    process
    {
        if ($index++ -eq 0)
        {
            $null = $previous = $InputObject
        } else
        {
            $a = $previous
            $b = $InputObject
            $null = $previous = $InputObject

            if ($Operation)
            {
                $Operation.Invoke($a, $b)
            } else
            {
                , @($a, $b)
            }
        }
    }
}

function Reduce-Object
{
    <#
    .SYNOPSIS
        Reduces a collection to a single value by applying a script block cumulatively.

    .DESCRIPTION
        Reduce-Object applies a script block to each element in the collection, accumulating the result.
        The default script block adds values together (sum).

    .EXAMPLE
        1 .. 10 | Reduce-Object
        # Returns 55 (sum of 1 through 10)

    .EXAMPLE
        1 .. 5 | Reduce-Object { $args[0] * $args[1] }
        # Returns 120 (product of 1 through 5)

    .EXAMPLE
        1 .. 5 | Reduce-Object { $args[0] + $args[1] } -InitialValue 100
        # Returns 115 (100 + sum of 1 through 5)
    #>
    [CmdletBinding()]
    [Alias("Reduce")]
    [Alias("Sum")]
    [OutputType([Int])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Array] $InputObject,
        [Parameter(Position = 0)]
        [ScriptBlock] $ScriptBlock = { $args[0] + $args[1] },
        [Parameter(Position = 1)]
        [Int] $InitialValue = 0
    )
    begin
    {
        if ($InitialValue) { $Accumulator = $InitialValue }
    }
    process
    {
        foreach ($Value in $InputObject)
        {
            if ($Accumulator)
            {
                $Accumulator = $ScriptBlock.InvokeReturnAsIs($Accumulator, $Value)
            } else
            {
                $Accumulator = $Value
            }
        }
    }
    end { $Accumulator }
}

function Map-Object
{
    <#
    .SYNOPSIS
        Transforms each element in a collection using a script block.

    .DESCRIPTION
        Map-Object applies a script block to each element in the input collection and returns the transformed results.
        This is equivalent to "map" or "select" in functional programming.

    .EXAMPLE
        1 .. 5 | Map-Object { $_ * 2 }
        # Returns 2, 4, 6, 8, 10

    .EXAMPLE
        @('a', 'b', 'c') | Map { $_.ToUpper() }
        # Returns A, B, C

    .EXAMPLE
        1 .. 3 | Map { [PSCustomObject]@{ Value = $_ } }
        # Returns custom objects with Value property
    #>
    [CmdletBinding()]
    [Alias("Map")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock
    )

    process
    {
        ,$InputObject | ForEach-Object $ScriptBlock
    }
}

function Filter-Object
{
    <#
    .SYNOPSIS
        Filters elements from a collection based on a predicate script block.

    .DESCRIPTION
        Filter-Object keeps only elements where the predicate script block returns true.
        This is equivalent to "filter" or "where" in functional programming.

    .EXAMPLE
        1 .. 10 | Filter-Object { $_ % 2 -eq 0 }
        # Returns 2, 4, 6, 8, 10

    .EXAMPLE
        Get-Service | Filter { $_.Status -eq 'Running' }
        # Returns only running services

    .EXAMPLE
        1 .. 5 | Filter { $_ -gt 3 }
        # Returns 4, 5
    #>
    [CmdletBinding()]
    [Alias("Filter")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$Predicate
    )

    process
    {
        ,$InputObject | Where-Object $Predicate
    }
}

function Flatten-Object
{
    <#
    .SYNOPSIS
        Flattens nested arrays one level deep.

    .DESCRIPTION
        Flatten-Object takes nested arrays and flattens them one level.
        Arrays nested deeper than one level are not fully flattened.

    .EXAMPLE
        @(1, @(2, 3), 4) | Flatten-Object
        # Returns 1, 2, 3, 4

    .EXAMPLE
        @(1, @(2, @(3, 4)), 5) | Flatten-Object
        # Returns 1, 2, @(3, 4), 5 (only one level flattened)
    #>
    [CmdletBinding()]
    [Alias("Flatten")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    process
    {
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string] -and $InputObject.GetType().IsArray)
        {
            foreach ($item in $InputObject)
            {
                if ($item -is [System.Collections.IEnumerable] -and $item -isnot [string] -and $item.GetType().IsArray)
                {
                    ,$item
                }
                else
                {
                    $item
                }
            }
        }
        else
        {
            $InputObject
        }
    }
}

function FlatMap-Object
{
    <#
    .SYNOPSIS
        Maps each element to a collection and flattens the results.

    .DESCRIPTION
        FlatMap-Object applies a script block to each element (which should return a collection),
        then flattens all the collections into a single result. This is equivalent to "flatMap" or
        "collect" in functional programming.

    .EXAMPLE
        1 .. 3 | FlatMap-Object { $_; $_ * 2 }
        # Returns 1, 2, 2, 4, 3, 6

    .EXAMPLE
        @('a b', 'c d') | FlatMap-Object { $_.Split(' ') }
        # Returns a, b, c, d
    #>
    [CmdletBinding()]
    [Alias("FlatMap")]
    [Alias("Collect")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock
    )

    process
    {
        $result = ,$InputObject | ForEach-Object $ScriptBlock
        if ($result -is [System.Collections.IEnumerable] -and $result -isnot [string])
        {
            foreach ($item in $result)
            {
                $item
            }
        }
        else
        {
            $result
        }
    }
}

function Take-Object
{
    <#
    .SYNOPSIS
        Takes the first n elements from a collection.

    .DESCRIPTION
        Take-Object returns the first n elements from the input collection.
        If n is larger than the collection size, all elements are returned.

    .EXAMPLE
        1 .. 10 | Take-Object 3
        # Returns 1, 2, 3

    .EXAMPLE
        1 .. 5 | Take 10
        # Returns 1, 2, 3, 4, 5
    #>
    [CmdletBinding()]
    [Alias("Take")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [int]$Count
    )

    begin
    {
        $taken = 0
    }

    process
    {
        if ($taken -lt $Count)
        {
            $InputObject
            $taken++
        }
    }
}

function Take-WhileObject
{
    <#
    .SYNOPSIS
        Takes elements while a predicate is true.

    .DESCRIPTION
        Take-WhileObject returns elements from the start of the collection
        as long as the predicate returns true. Stops at the first false result.

    .EXAMPLE
        1 .. 10 | Take-WhileObject { $_ -lt 5 }
        # Returns 1, 2, 3, 4

    .EXAMPLE
        1 .. 5 | TakeWhile { $true }
        # Returns 1, 2, 3, 4, 5
    #>
    [CmdletBinding()]
    [Alias("TakeWhile")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$Predicate
    )

    begin
    {
        $taking = $true
    }

    process
    {
        if ($taking)
        {
            $result = ,$InputObject | ForEach-Object $Predicate
            if ($result)
            {
                $InputObject
            }
            else
            {
                $taking = $false
            }
        }
    }
}

function Skip-Object
{
    <#
    .SYNOPSIS
        Skips the first n elements from a collection.

    .DESCRIPTION
        Skip-Object skips the first n elements from the input collection
        and returns the rest.

    .EXAMPLE
        1 .. 10 | Skip-Object 3
        # Returns 4, 5, 6, 7, 8, 9, 10

    .EXAMPLE
        1 .. 3 | Skip 10
        # Returns nothing (skips more than available)
    #>
    [CmdletBinding()]
    [Alias("Skip")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [int]$Count
    )

    begin
    {
        $skipped = 0
    }

    process
    {
        if ($skipped -ge $Count)
        {
            $InputObject
        }
        else
        {
            $skipped++
        }
    }
}

function Skip-WhileObject
{
    <#
    .SYNOPSIS
        Skips elements while a predicate is true.

    .DESCRIPTION
        Skip-WhileObject skips elements from the start of the collection
        as long as the predicate returns true. Returns all remaining elements
        starting from the first false result.

    .EXAMPLE
        1 .. 10 | Skip-WhileObject { $_ -lt 5 }
        # Returns 5, 6, 7, 8, 9, 10

    .EXAMPLE
        1 .. 5 | SkipWhile { $_ -gt 10 }
        # Returns 1, 2, 3, 4, 5 (predicate false immediately)
    #>
    [CmdletBinding()]
    [Alias("SkipWhile")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$Predicate
    )

    begin
    {
        $skipping = $true
    }

    process
    {
        if ($skipping)
        {
            $result = ,$InputObject | ForEach-Object $Predicate
            if (!$result)
            {
                $skipping = $false
                $InputObject
            }
        }
        else
        {
            $InputObject
        }
    }
}

function Reverse-Object
{
    <#
    .SYNOPSIS
        Reverses the order of elements in a collection.

    .DESCRIPTION
        Reverse-Object returns elements in reverse order.
        Note: This function accumulates all input before outputting.

    .EXAMPLE
        1 .. 5 | Reverse-Object
        # Returns 5, 4, 3, 2, 1

    .EXAMPLE
        @('a', 'b', 'c') | Reverse
        # Returns c, b, a
    #>
    [CmdletBinding()]
    [Alias("Reverse")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    begin
    {
        $items = [System.Collections.Generic.List[object]]::new()
    }

    process
    {
        $items.Add($InputObject)
    }

    end
    {
        for ($i = $items.Count - 1; $i -ge 0; $i--)
        {
            $items[$i]
        }
    }
}

function Group-ObjectBy
{
    <#
    .SYNOPSIS
        Groups elements by a key selector function.

    .DESCRIPTION
        Group-ObjectBy groups collection elements by the value returned
        by a key selector script block. Returns groups with Key and Group properties.

    .EXAMPLE
        1 .. 6 | Group-ObjectBy { $_ % 2 }
        # Returns two groups: Key=0 (even numbers) and Key=1 (odd numbers)

    .EXAMPLE
        @('a', 'bb', 'ccc') | GroupBy { $_.Length }
        # Returns groups by string length
    #>
    [CmdletBinding()]
    [Alias("GroupBy")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$KeySelector
    )

    begin
    {
        $groups = @{}
    }

    process
    {
        $key = ,$InputObject | ForEach-Object $KeySelector
        if ($null -eq $key)
        {
            $key = [guid]::Empty
        }
        
        if (-not $groups.ContainsKey($key))
        {
            $groups[$key] = [System.Collections.Generic.List[object]]::new()
        }
        $groups[$key].Add($InputObject)
    }

    end
    {
        foreach ($kvp in $groups.GetEnumerator())
        {
            [PSCustomObject]@{
                Key = $kvp.Key
                Group = $kvp.Value
            }
        }
    }
}

function Confirm-AnyObject
{
    <#
    .SYNOPSIS
        Tests if any element in the collection satisfies a predicate.

    .DESCRIPTION
        Test-AnyObject returns true if any element satisfies the predicate,
        or if the collection is non-empty when no predicate is provided.

    .EXAMPLE
        1 .. 5 | Confirm-AnyObject { $_ -gt 3 }
        # Returns True

    .EXAMPLE
        1 .. 5 | Confirm-AnyObject { $_ -gt 10 }
        # Returns False

    .EXAMPLE
        @() | Confirm-AnyObject
        # Returns False
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Position = 0)]
        [scriptblock]$Predicate
    )

    begin
    {
        $found = $false
    }

    process
    {
        if (-not $found)
        {
            if ($Predicate)
            {
                $result = ,$InputObject | ForEach-Object $Predicate
                if ($result)
                {
                    $found = $true
                }
            }
            else
            {
                $found = $true
            }
        }
    }

    end
    {
        $found
    }
}

function Confirm-AllObject
{
    <#
    .SYNOPSIS
        Tests if all elements in the collection satisfy a predicate.

    .DESCRIPTION
        Test-AllObject returns true if all elements satisfy the predicate.
        Returns true for empty collections (vacuous truth).

    .EXAMPLE
        2 .. 10 | Confirm-AllObject { $_ % 2 -eq 0 }
        # Returns True

    .EXAMPLE
        1 .. 5 | Confirm-AllObject { $_ -gt 3 }
        # Returns False

    .EXAMPLE
        @() | Confirm-AllObject { $true }
        # Returns True (vacuous truth)
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$Predicate
    )

    begin
    {
        $all = $true
        $hasElements = $false
    }

    process
    {
        $hasElements = $true
        if ($all)
        {
            $result = ,$InputObject | ForEach-Object $Predicate
            if (-not $result)
            {
                $all = $false
            }
        }
    }

    end
    {
        # Return true for empty collections (vacuous truth)
        if (-not $hasElements)
        {
            return $true
        }
        $all
    }
}

function Select-FirstObject
{
    <#
    .SYNOPSIS
        Returns the first element or first matching element.

    .DESCRIPTION
        Select-FirstObject returns the first element, or the first element
        that satisfies the predicate. Returns null if no match found.

    .EXAMPLE
        1 .. 5 | Select-FirstObject
        # Returns 1

    .EXAMPLE
        1 .. 10 | First { $_ % 3 -eq 0 }
        # Returns 3

    .EXAMPLE
        @() | Find { $true }
        # Returns null
    #>
    [CmdletBinding()]
    [Alias("First")]
    [Alias("Find")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Position = 0)]
        [scriptblock]$Predicate
    )

    begin
    {
        $found = $false
    }

    process
    {
        if (-not $found)
        {
            if ($Predicate)
            {
                $result = ,$InputObject | ForEach-Object $Predicate
                if ($result)
                {
                    $InputObject
                    $found = $true
                }
            }
            else
            {
                $InputObject
                $found = $true
            }
        }
    }
}

function Select-LastObject
{
    <#
    .SYNOPSIS
        Returns the last element of a collection.

    .DESCRIPTION
        Select-LastObject returns the last element received.
        Note: This function accumulates all input before returning.

    .EXAMPLE
        1 .. 5 | Select-LastObject
        # Returns 5

    .EXAMPLE
        @('a', 'b', 'c') | Last
        # Returns c
    #>
    [CmdletBinding()]
    [Alias("Last")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    begin
    {
        $last = $null
    }

    process
    {
        $last = $InputObject
    }

    end
    {
        $last
    }
}

function Select-HeadObject
{
    <#
    .SYNOPSIS
        Returns the first element of a collection safely.

    .DESCRIPTION
        Select-HeadObject returns the first element, or null if the collection is empty.
        Similar to First-Object but explicitly named for "head" operation semantics.

    .EXAMPLE
        1 .. 5 | Select-HeadObject
        # Returns 1

    .EXAMPLE
        @() | Head
        # Returns null
    #>
    [CmdletBinding()]
    [Alias("Head")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    begin
    {
        $headReturned = $false
    }

    process
    {
        if (-not $headReturned)
        {
            $InputObject
            $headReturned = $true
        }
    }
}

function Select-TailObject
{
    <#
    .SYNOPSIS
        Returns all elements except the first.

    .DESCRIPTION
        Select-TailObject returns all elements after the first one.
        Returns empty for single-element or empty collections.

    .EXAMPLE
        1 .. 5 | Select-TailObject
        # Returns 2, 3, 4, 5

    .EXAMPLE
        @(1) | Tail
        # Returns nothing
    #>
    [CmdletBinding()]
    [Alias("Tail")]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    begin
    {
        $firstSkipped = $false
    }

    process
    {
        if ($firstSkipped)
        {
            $InputObject
        }
        else
        {
            $firstSkipped = $true
        }
    }
}

function Fold-Object
{
    <#
    .SYNOPSIS
        Reduces a collection to a single value, always starting with an initial value.

    .DESCRIPTION
        Fold-Object is similar to Reduce-Object but requires an initial value.
        This ensures consistent behavior and avoids issues with empty collections.

    .EXAMPLE
        1 .. 5 | Fold-Object { $args[0] + $args[1] } -InitialValue 10
        # Returns 25 (10 + 1 + 2 + 3 + 4 + 5)

    .EXAMPLE
        1 .. 4 | Fold { $args[0] * $args[1] } -InitialValue 1
        # Returns 24 (1 * 1 * 2 * 3 * 4)
    #>
    [CmdletBinding()]
    [Alias("Fold")]
    [OutputType([object])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory, Position = 1)]
        [object]$InitialValue
    )

    begin
    {
        $accumulator = $InitialValue
    }

    process
    {
        $accumulator = $ScriptBlock.InvokeReturnAsIs($accumulator, $InputObject)
    }

    end
    {
        $accumulator
    }
}

function Count-ObjectWhere
{
    <#
    .SYNOPSIS
        Counts elements in a collection that satisfy a predicate.

    .DESCRIPTION
        Count-ObjectWhere returns the number of elements for which the predicate
        returns true. If no predicate is provided, returns the total count.

    .EXAMPLE
        1 .. 10 | Count-ObjectWhere { $_ % 2 -eq 0 }
        # Returns 5 (count of even numbers)

    .EXAMPLE
        1 .. 10 | Count { $_ -lt 5 }
        # Returns 4
    #>
    [CmdletBinding()]
    [Alias("Count")]
    [OutputType([int])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Position = 0)]
        [scriptblock]$Predicate
    )

    begin
    {
        $count = 0
    }

    process
    {
        if ($Predicate)
        {
            if (,$InputObject | ForEach-Object $Predicate)
            {
                $count++
            }
        }
        else
        {
            $count++
        }
    }

    end
    {
        $count
    }
}

function Initialize-Sequence
{
    <#
    .SYNOPSIS
        Generates a sequence of numbers.

    .DESCRIPTION
        Initialize-Sequence creates a sequence of integers from start to end,
        optionally with a custom step. Can also generate a specific count of numbers.

    .EXAMPLE
        Initialize-Sequence -Start 1 -End 5
        # Returns 1, 2, 3, 4, 5

    .EXAMPLE
        Initialize-Sequence -Start 1 -End 10 -Step 2
        # Returns 1, 3, 5, 7, 9

    .EXAMPLE
        Initialize-Sequence -Start 1 -Count 5
        # Returns 1, 2, 3, 4, 5
    #>
    [CmdletBinding()]
    [Alias("Range")]
    [OutputType([int[]])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [int]$Start,

        [Parameter(ParameterSetName = 'End', Position = 1)]
        [int]$End,

        [Parameter(ParameterSetName = 'Step')]
        [Parameter(ParameterSetName = 'End')]
        [int]$Step = 1,

        [Parameter(ParameterSetName = 'Count', Mandatory)]
        [int]$Count
    )

    begin
    {
        $result = [System.Collections.Generic.List[int]]::new()
    }

    process
    {
        if ($Count)
        {
            for ($i = $Start; $i -lt $Start + $Count; $i++)
            {
                $result.Add($i)
            }
        }
        else
        {
            if ($Step -eq 0)
            {
                throw "Step cannot be zero"
            }

            if ($Step -gt 0)
            {
                for ($i = $Start; $i -le $End; $i += $Step)
                {
                    $result.Add($i)
                }
            }
            else
            {
                for ($i = $Start; $i -ge $End; $i += $Step)
                {
                    $result.Add($i)
                }
            }
        }
    }

    end
    {
        $result.ToArray()
    }
}
