# Property selector functions are in DotEasyOutHelper.PropertySelector.ps1

function Use-EasyOut
{
    <#
    .SYNOPSIS
    Interactive EZOut formatting helper with custom property selection.

    .DESCRIPTION
    Simplifies creating EZOut format views by automatically detecting types and properties.
    Uses custom property selector with value preview in table format.
    Automatically creates formatting directory structure and checks for EZOut build files.

    .PARAMETER InputObject
    Object to analyze for type and properties.

    .PARAMETER Path
    Output path for format file. Defaults to ./Formatting/[TypeName].format.ps1

    .PARAMETER Interactive
    Run interactively without saving to file.

    .PARAMETER TypePrefix
    Prefix for format view names. Default is "DotFormat".

    .PARAMETER ModuleName
    Module name for EZOut file detection. Auto-detected from current directory.

    .EXAMPLE
    $product | easy

    .EXAMPLE
    Get-Process | Select-Object -First 1 | easy -Path ./custom.format.ps1

    .EXAMPLE
    $data | easy -Interactive

    .OUTPUTS
    None (writes to file) or InputObject (if -Interactive)
    #>
    [CmdletBinding()]
    [Alias('easy')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter()]
        [string]$Path,

        [Parameter()]
        [switch]$Interactive,

        [Parameter()]
        [string]$TypePrefix = "DotFormat",

        [Parameter()]
        [string]$ModuleName
    )

    begin
    {
        # Auto-detect module name from current directory
        if (-not $ModuleName)
        {
            $currentDir = Get-Location
            $ModuleName = [System.IO.Path]::GetFileName($currentDir.Path)
            Write-Verbose "Auto-detected module name: $ModuleName"
        }

        # Check for EZOut build file and create if missing
        $ezoutFile = Join-Path -Path $currentDir.Path -ChildPath "$ModuleName.EzFormat.ps1"

        if (-not (Test-Path $ezoutFile))
        {
            Write-Host "EZOut build file not found. Creating: $ezoutFile" -ForegroundColor Yellow
            Write-EZFormatFile | Set-Content $ezoutFile -Encoding UTF8
            Write-Host "Created EZOut build file. Run './$ModuleName.EzFormat.ps1' to generate format views." -ForegroundColor Green
        }
    }

    # Do not use process block since I only want the top level object
    process
    {
    }
    end
    {
        # Get type names and select the most specific one
        $typeNames = $InputObject.PSObject.TypeNames
        Write-Verbose "Available TypeNames: $($typeNames -join ', ')"

        # Auto-select the most specific type name
        $Type = $typeNames | Where-Object {
            $_ -ne 'System.Management.Automation.PSCustomObject' -and
            $_ -ne 'System.Object' -and
            $_ -ne 'System.Management.Automation.PSCustomObject'
        } | Select-Object -First 1

        if (-not $Type)
        {
            $Type = $typeNames | Select-Object -First 1
        }

        Write-Verbose "Auto-selected type: $Type"

        if (-not $Type)
        {
            throw "Unable to determine type name from object"
        }

        # Get properties using custom property selector
        $Properties = Show-PropertySelector -InputObject $InputObject

        if (-not $Properties -or $Properties.Count -eq 0)
        {
            Write-Warning "No properties selected. Using default properties."
            # Fallback: select common display properties
            $allProperties = $InputObject.PSObject.Properties | Select-Object -ExpandProperty Name
            $Properties = $allProperties | Where-Object { $_ -notlike 'PS*' -and $_ -notlike 'ApiData' } |
                Select-Object -First 5

            if (-not $Properties)
            {
                $Properties = $allProperties | Select-Object -First 5
            }

            # Convert back to objects for compatibility
            $Properties = $Properties | ForEach-Object { [PSCustomObject]@{ Name = $_ } }
        }

        Write-Verbose "Selected properties: $($Properties.Count)"

        $PropertiesString = $Properties | Select-Object -ExpandProperty Name | ForEach-Object { "'$_'" } | Join-String -Separator ', '
        $TypeName = $Type -replace '\.', '_'

        $EasyOutString = @"
`$splat = @{
    TypeName = '$Type'
    Name = '$TypePrefix_$TypeName'
    Property = @($PropertiesString)
    AutoSize = `$true
};
Write-FormatView @splat
"@

        if ($Interactive)
        {
            Write-Host "Running EZOut for interactive formatting, not saving to a file. Code to run`n" -ForegroundColor Green
            Write-Host "$EasyOutString" -ForegroundColor Yellow
            $EasyOutString += ' | Out-FormatData | Push-FormatData'
            Invoke-Expression $EasyOutString

            return $InputObject
        }

        # Determine output path
        $resolvedPath = if ($Path)
        {
            $Path
        } else
        {
            # Default to ./Formatting/[TypeName].format.ps1
            $cleanTypeName = if ($Type)
            {
                $Type -replace '[^\w\d]', '_'
            } else
            {
                'CustomType'
            }

            # Ensure we don't have empty type names
            if ([string]::IsNullOrWhiteSpace($cleanTypeName))
            {
                $cleanTypeName = 'CustomType'
                Write-Warning "Type name was empty, using 'CustomType' instead"
            }

            "./Formatting/$cleanTypeName.format.ps1"
        }

        Write-Verbose "Output path: $resolvedPath"

        # Double-check we don't have an invalid filename
        if ($resolvedPath -match '\.\/Formatting\/\.format\.ps1$')
        {
            throw "Invalid path generated: $resolvedPath. Type name may be empty."
        }

        # Create directory if it doesn't exist
        $directory = [System.IO.Path]::GetDirectoryName($resolvedPath)
        if (-not (Test-Path $directory))
        {
            Write-Host "Creating directory: $directory" -ForegroundColor Yellow
            New-Item -ItemType Directory $directory -Force | Out-Null
        }

        # Write content to file
        Write-Host "Writing format view to: $resolvedPath" -ForegroundColor Green
        Add-Content -Path $resolvedPath -Value "`n$EasyOutString"

        # Return the path
        $resolvedPath
    }
}
