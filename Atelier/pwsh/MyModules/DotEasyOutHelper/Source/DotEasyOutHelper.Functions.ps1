function Use-EasyOut
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,
        [switch]$Interactive
    )

    dynamicparam
    {
        if (-not $PSBoundParameters['Interactive'])
        {
            $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

            # Defining parameter attributes
            $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributes = New-Object System.Management.Automation.ParameterAttribute
            $attributes.ParameterSetName = '__AllParameterSets'
            $attributes.Mandatory = $True
            $attributeCollection.Add($attributes)

            # Defining the runtime parameter
            $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter('Path', [String], $attributeCollection)
            $paramDictionary.Add('Path', $dynParam1)

            return $paramDictionary
        }
    }

    # Do not use process block since I only want to top level object
    process
    {
    }
    end
    {

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

        if($PSBoundParameters.ContainsKey('Path'))
        {
            $Path = $PSBoundParameters['Path']
            $Path
        } else
        {
            throw 'Path param has not been set'
        }

        $Path

        $directory = [System.IO.Path]::GetDirectoryName($Path)
        New-Item -ItemType Directory $directory -ErrorAction SilentlyContinue

        Write-Host "Writing content to file: $Path"
        Add-Content -Path $Path -Value "`n$EasyOutString"
    }
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
