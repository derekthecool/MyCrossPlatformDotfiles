function Invoke-RestMethodAsList
{
    [CmdletBinding()]
    [Alias('rest')]

    $result = Invoke-RestMethod @PSBoundParameters
    $result.psobject.typenames.Add('DotInvokeRestForceList')
    $result
}
