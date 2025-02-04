function Get-BytesToSize
{
    param (
        [Parameter()]
        [int]$Bytes
    )

    $sizeUnits = @("B", "KB", "MB", "GB", "TB", "PB")
    $i = 0
    $size = $Bytes

    # Loop through until the value is smaller than 1024 or we've hit the largest size unit (PB)
    while ($size -ge 1024 -and $i -lt $sizeUnits.Length - 1)
    {
        $size /= 1024
        $i++
    }

    if($Bytes -lt 1kb)
    {
        return "$size$($sizeUnits[$i])"
    } else
    {
        # Format the size to 2 decimal places and append the appropriate unit
        return "{0:N2}{1}" -f $size, $sizeUnits[$i]
    }

}

function number
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [int[]]$Number
    )

    Process
    {
        $Number | ForEach-Object {
            $CurrentNumber = $_

            $DecimalFormat = $PSStyle.Foreground.White + $CurrentNumber + $PSStyle.Foreground.White

            $Hex = [Convert]::ToString($CurrentNumber, 16)
            $HexFormat = $PSStyle.Foreground.Cyan + "0x" + $Hex + $PSStyle.Foreground.White

            $Binary = [Convert]::ToString($CurrentNumber, 2)
            $BinaryFormat = $PSStyle.Foreground.Yellow + "0b" + $Binary + $PSStyle.Foreground.White

            $Size = Get-BytesToSize -Bytes $CurrentNumber
            $SizeFormat = $PSStyle.Foreground.Blue + $Size + $PSStyle.Foreground.White

            [PSCustomObject]@{
                Number = $CurrentNumber
                Formatted = "$DecimalFormat $HexFormat $BinaryFormat $SizeFormat"
            }
        }
    }
}
