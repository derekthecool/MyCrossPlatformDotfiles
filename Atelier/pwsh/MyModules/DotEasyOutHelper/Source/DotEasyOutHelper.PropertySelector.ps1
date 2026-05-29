function Show-PropertySelector {
    <#
    .SYNOPSIS
    Interactive property selector using PwshSpectreConsole.

    .DESCRIPTION
    Displays object properties in a table format with values for preview.
    Allows multi-selection using Read-SpectreMultiSelection interface.

    .PARAMETER InputObject
    Object to analyze for properties and values.

    .EXAMPLE
    Show-PropertySelector -InputObject $object

    .OUTPUTS
    Array of selected property names.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )

    process {
        # Check if PwshSpectreConsole is available
        if (-not (Get-Module -ListAvailable -Name PwshSpectreConsole)) {
            Write-Warning "PwshSpectreConsole module not found. Using fallback selection."
            return Select-PropertiesFallback -InputObject $InputObject
        }

        # Import PwshSpectreConsole
        Import-Module PwshSpectreConsole -ErrorAction Stop

        # Get all properties and their values
        $propertyList = foreach ($prop in $InputObject.PSObject.Properties) {
            $propValue = $prop.Value
            $propType = if ($null -eq $propValue) {
                "Null"
            }
            else {
                $propValue.GetType().Name
            }

            $displayValue = if ($null -eq $propValue) {
                "<null>"
            }
            elseif ($propValue -is [array]) {
                "[Array: $($propValue.Count) items]"
            }
            elseif ($propValue.GetType().Name -like 'List*') {
                "[List: $($propValue.Count) items]"
            }
            elseif ($propValue -is [hashtable] -or $propValue -is [System.Collections.Specialized.OrderedDictionary]) {
                "[Hashtable: $($propValue.Count) keys]"
            }
            elseif ($propValue -is [bool]) {
                if ($propValue) { "True" } else { "False" }
            }
            elseif ($propValue -is [string]) {
                if ($propValue.Length -gt 50) {
                    $propValue.Substring(0, 47) + "..."
                }
                else {
                    $propValue
                }
            }
            else {
                try {
                    $stringVal = $propValue.ToString()
                    if ($stringVal.Length -gt 50) {
                        $stringVal.Substring(0, 47) + "..."
                    }
                    else {
                        $stringVal
                    }
                }
                catch {
                    "<$propType>"
                }
            }

            [PSCustomObject]@{
                Name = $prop.Name
                Value = $displayValue
                Type = $propType
                OriginalObject = $prop  # Store reference for easy access
            }
        }

        # Convert to array and filter out internal PowerShell properties
        $propertyArray = @($propertyList) | Where-Object { $_.Name -notlike 'PS*' -and $_.Name -ne 'ApiData' }

        if ($propertyArray.Count -eq 0) {
            Write-Warning "No properties found on object."
            return @()
        }

        # Use Read-SpectreMultiSelection for interactive selection
        try {
            # Create display labels that show property name, value, and type
            $choices = $propertyArray | ForEach-Object {
                $displayValue = $_.Value
                $typeInfo = "<$($_.Type)>"
                "$($_.Name) = $displayValue $typeInfo"
            }

            # Use Read-SpectreMultiSelection with proper syntax
            $selectedLabels = Read-SpectreMultiSelection -Message "Select properties for formatting" -Choices $choices -PageSize 10

            if ($null -eq $selectedLabels -or $selectedLabels.Count -eq 0) {
                Write-Warning "No properties selected. Using default selection (first 5 properties)."
                $defaultProps = $propertyArray | Select-Object -First 5
                return $defaultProps | ForEach-Object { [PSCustomObject]@{ Name = $_.Name } }
            }

            # Map selected labels back to property objects
            $selectedProperties = foreach ($label in $selectedLabels) {
                $propertyArray | Where-Object {
                    $displayValue = $_.Value
                    $typeInfo = "<$($_.Type)>"
                    $label -eq "$($_.Name) = $displayValue $typeInfo"
                }
            }

            $selectedNames = $selectedProperties.Name -join ', '
            Write-Host "Selected properties: $selectedNames" -ForegroundColor Green

            # Return selected properties as compatibility objects
            return $selectedProperties | ForEach-Object { [PSCustomObject]@{ Name = $_.Name } }
        }
        catch {
            Write-Warning "Read-SpectreMultiSelection failed: $_. Using fallback selection."
            return Select-PropertiesFallback -InputObject $InputObject
        }
    }
}

function Select-PropertiesFallback {
    <#
    .SYNOPSIS
    Fallback property selection when interactive selection is not desired.

    .DESCRIPTION
    Returns top N properties automatically without user interaction.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,

        [Parameter()]
        [int]$Top = 5
    )

    process {
        $propertyList = $InputObject.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' -and $_.Name -ne 'ApiData' }

        if ($propertyList.Count -eq 0) {
            Write-Warning "No properties found on object."
            return @()
        }

        Write-Host "Auto-selecting top $Top properties: $($propertyList[0..($Top-1)].Name -join ', ')" -ForegroundColor Green

        return $propertyList | Select-Object -First $Top | ForEach-Object { [PSCustomObject]@{ Name = $_.Name } }
    }
}
