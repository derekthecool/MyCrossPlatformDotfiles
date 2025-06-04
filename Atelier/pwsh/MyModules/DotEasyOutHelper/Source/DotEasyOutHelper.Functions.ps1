function Use-EasyOut
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [switch]$Interactive
    )

    $Type = Show-Menu -MenuItems $($InputObject.PSObject.TypeNames)
    Write-Verbose "Type: $Type"

    $Properties = Show-Menu -MenuItems $($InputObject.PSObject.Properties) -MenuItemFormatter { $args | Select-Object -ExpandProperty Name } -MultiSelect
    Write-Verbose "Properties: $Properties"

    $PropertiesString = $Properties | Select-Object -ExpandProperty Name | ForEach-Object { "'$_'" } | Join-String -Separator ', '
    $TypeName = $Type -replace '\.', '_'

    $EasyOutString = @"
`$splat = @{
    TypeName = '$Type'
    Name = 'DotFormat_$TypeName'
    Property = @($PropertiesString)
    AutoSize = `$true
};
Write-FormatView @splat
"@

    if($Interactive)
    {
        Write-Host "Running EZOut for interactive formatting, not saving to a file. Code to run`n" -ForegroundColor Green
        Write-Host "$EasyOutString" -ForegroundColor Yellow
        $EasyOutString += ' | Out-FormatData | Push-FormatData'
        Invoke-Expression $EasyOutString

        return $InputObject
    }

    # $EasyOutString
    # Write-Output $InputObject
}

New-Alias -Name 'easy' -Value Use-EasyOut

<#
# Pretty much the same as aliases but for executables instead
Write-FormatView `
    -TypeName 'System.Management.Automation.ApplicationInfo' `
    -Name DotsApplicationInfoView `
    -Property Name, Definition, CommandType `
    -AutoSize `
    -StyleRow {
    'Foreground.Yellow'
}
#>
