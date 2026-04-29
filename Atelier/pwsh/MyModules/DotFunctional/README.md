# DotFunctional

A functional programming library for PowerShell, providing common higher-order functions like `Map`, `Filter`, `Reduce`, and more.

## Installation

```powershell
Import-Module /path/to/DotFunctional.psd1
```

## Available Functions

### Core Functions

| Function         | Aliases              | Description                                    |
|------------------|----------------------|------------------------------------------------|
| `Format-Pairs`   | `Zip`                | Creates pairs from consecutive elements        |
| `Reduce-Object`  | `Reduce`, `Sum`      | Reduces a collection to a single value         |
| `Map-Object`     | `Map`                | Transforms each element using a script block   |
| `Filter-Object`  | `Filter`             | Filters elements based on a predicate          |
| `Fold-Object`    | `Fold`               | Reduces collection with explicit initial value |
| `Flatten-Object` | `Flatten`            | Flattens nested arrays one level deep          |
| `FlatMap-Object` | `FlatMap`, `Collect` | Maps then flattens results                     |

### Sequence Functions

| Function           | Aliases     | Description                            |
|--------------------|-------------|----------------------------------------|
| `Take-Object`      | `Take`      | Takes first n elements                 |
| `Take-WhileObject` | `TakeWhile` | Takes elements while predicate is true |
| `Skip-Object`      | `Skip`      | Skips first n elements                 |
| `Skip-WhileObject` | `SkipWhile` | Skips elements while predicate is true |
| `Reverse-Object`   | `Reverse`   | Reverses the order of elements         |

### Query Functions

| Function            | Aliases   | Description                                |
|---------------------|-----------|--------------------------------------------|
| `Group-ObjectBy`    | `GroupBy` | Groups elements by a key function          |
| `Confirm-AnyObject` | -         | Tests if any element satisfies a predicate |
| `Confirm-AllObject` | -         | Tests if all elements satisfy a predicate  |
| `Count-ObjectWhere` | `Count`   | Count elements matching a predicate        |

### Selection Functions

| Function             | Aliases         | Description                          |
|----------------------|-----------------|--------------------------------------|
| `Select-FirstObject` | `First`, `Find` | Returns first element or first match |
| `Select-LastObject`  | `Last`          | Returns last element                 |
| `Select-HeadObject`  | `Head`          | Returns first element safely         |
| `Select-TailObject`  | `Tail`          | Returns all except first element     |

### Utility Functions

| Function              | Aliases | Description                    |
|-----------------------|---------|--------------------------------|
| `Initialize-Sequence` | `Range` | Generates sequences of numbers |

## Usage Examples

### Map-Object (Map)
Transform each element in a collection:
```powershell
1 .. 5 | Map-Object { $_ * 2 }
# Returns: 2, 4, 6, 8, 10

@('a', 'b', 'c') | Map { $_.ToUpper() }
# Returns: A, B, C
```

### Filter-Object (Filter)
Filter elements based on a condition:
```powershell
1 .. 10 | Filter-Object { $_ % 2 -eq 0 }
# Returns: 2, 4, 6, 8, 10

Get-Service | Filter { $_.Status -eq 'Running' }
# Returns only running services
```

### Reduce-Object (Reduce, Sum)
Reduce collection to a single value:
```powershell
1 .. 10 | Reduce-Object { $args[0] + $args[1] }
# Returns: 55 (sum)

1 .. 10 | Sum
# Returns: 55
```

### Fold-Object (Fold)
Reduce with explicit initial value:
```powershell
1 .. 5 | Fold-Object { $args[0] + $args[1] } -InitialValue 10
# Returns: 25 (10 + 1 + 2 + 3 + 4 + 5)
```

### Flatten-Object (Flatten)
Flatten nested arrays:
```powershell
@(1, @(2, 3), 4) | Flatten-Object
# Returns: 1, 2, 3, 4
```

### Take-Object & Skip-Object
Take or skip elements:
```powershell
1 .. 10 | Take-Object 3
# Returns: 1, 2, 3

1 .. 10 | Skip-Object 5
# Returns: 6, 7, 8, 9, 10
```

### Group-ObjectBy (GroupBy)
Group elements by key:
```powershell
1 .. 6 | Group-ObjectBy { $_ % 2 }
# Returns two groups: evens and odds

@('a', 'bb', 'cc') | GroupBy { $_.Length }
# Returns groups by string length
```

### Initialize-Sequence (Range)
Generate sequences:
```powershell
Initialize-Sequence -Start 1 -End 5
# Returns: 1, 2, 3, 4, 5

Initialize-Sequence -Start 1 -End 10 -Step 2
# Returns: 1, 3, 5, 7, 9

Range -Start 1 -Count 5
# Returns: 1, 2, 3, 4, 5
```

## Pipeline-Based Design

All functions are designed to work seamlessly with PowerShell's pipeline:
```powershell
1 .. 100 |
  Filter { $_ % 3 -eq 0 } |
  Map  { $_ * 2 } |
  Take 10 |
  Sum
```

## Testing

Run the test suite with Pester:
```powershell
Invoke-Pester ./Test/
```

The module has comprehensive test coverage with 100% code coverage.

## Implementation Notes

- Uses PowerShell's object pipeline for idiomatic PowerShell
- Functions are documented with comment-based help
- TDD approach with Pester tests
- All functions use proper PowerShell verb-noun conventions
- Aliases provided for common functional programming names
- Avoids conflicts with Pester by not using "Any" or "All" aliases

## Resources

- [Highly detailed guide on PowerShell LINQ](https://www.red-gate.com/simple-talk/development/dotnet-development/high-performance-powershell-linq/)
