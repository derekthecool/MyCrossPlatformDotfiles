function Join-Item
{
    [CmdletBinding()]
    [Alias('join')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Position = 0)]
        [string]$Separator = ' ',

        [string]$Property
    )

    begin
    {
        $buffer = @()
    }

    process
    {
        $buffer += $InputObject
    }

    end
    {
        if ($Property)
        {
            $buffer | Select-Object -ExpandProperty $Property | Join-String -Separator $Separator
        } else
        {
            $buffer | Join-String -Separator $Separator
        }
    }
}
