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

    if ($Bytes -lt 1kb)
    {
        return "$size$($sizeUnits[$i])"
    } else
    {
        # Format the size to 2 decimal places and append the appropriate unit
        return "{0:N2}{1}" -f $size, $sizeUnits[$i]
    }
}
