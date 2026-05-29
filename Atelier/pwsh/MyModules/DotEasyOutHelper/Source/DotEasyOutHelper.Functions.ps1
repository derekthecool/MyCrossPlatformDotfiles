function Use-EasyOut {
    <#
    .SYNOPSIS
    Interactive EZOut formatting helper with smart defaults.

    .DESCRIPTION
    Simplifies creating EZOut format views by automatically detecting types and properties.
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

    begin {
        # Auto-detect module name from current directory
        if (-not $ModuleName) {
            $currentDir = Get-Location
            $ModuleName = [System.IO.Path]::GetFileName($currentDir.Path)
            Write-Verbose "Auto-detected module name: $ModuleName"
        }

        # Check for EZOut build file and create if missing
        $ezoutFile = Join-Path -Path $currentDir.Path -ChildPath "$ModuleName.EzFormat.ps1"

        if (-not (Test-Path $ezoutFile)) {
            Write-Host "EZOut build file not found. Creating: $ezoutFile" -ForegroundColor Yellow
            Write-EZFormatFile | Set-Content $ezoutFile -Encoding UTF8
            Write-Host "Created EZOut build file. Run './$ModuleName.EzFormat.ps1' to generate format views." -ForegroundColor Green
        }
    }

    # Do not use process block since I only want the top level object
    process {
    }
    end {
        $Type = Show-Menu -MenuItems $($InputObject.PSObject.TypeNames)
        Write-Verbose "Type: $Type"

        $Properties = Show-Menu -MenuItems $($InputObject.PSObject.Properties) -MenuItemFormatter { $args | Select-Object -ExpandProperty Name } -MultiSelect
        Write-Verbose "Properties: $Properties"

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

        if ($Interactive) {
            Write-Host "Running EZOut for interactive formatting, not saving to a file. Code to run`n" -ForegroundColor Green
            Write-Host "$EasyOutString" -ForegroundColor Yellow
            $EasyOutString += ' | Out-FormatData | Push-FormatData'
            Invoke-Expression $EasyOutString

            return $InputObject
        }

        # Determine output path
        $resolvedPath = if ($Path) {
            $Path
        }
        else {
            # Default to ./Formatting/[TypeName].format.ps1
            $cleanTypeName = $Type -replace '[^\w\d]', '_'
            "./Formatting/$cleanTypeName.format.ps1"
        }

        Write-Verbose "Output path: $resolvedPath"

        # Create directory if it doesn't exist
        $directory = [System.IO.Path]::GetDirectoryName($resolvedPath)
        if (-not (Test-Path $directory)) {
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
