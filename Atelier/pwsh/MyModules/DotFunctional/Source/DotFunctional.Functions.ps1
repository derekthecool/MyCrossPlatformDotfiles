function Format-Pairs
{
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

New-Alias -Name 'zip' -Value Format-Pairs
