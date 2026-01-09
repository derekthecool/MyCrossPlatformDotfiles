# https://blog.ironmansoftware.com/daily-powershell/powershell-linq/
# this could maybe be used, but it does not contain most of the Linq I want

function Format-Pairs
{
    [CmdletBinding()]
    [Alias("zip")]
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
    [CmdletBinding()]
    [Alias("reduce")]
    [OutputType([Int])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Array] $InputObject,
        [Parameter(Mandatory, Position = 0)]
        [ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory, Position = 1)]
        [Int] $InitialValue
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
