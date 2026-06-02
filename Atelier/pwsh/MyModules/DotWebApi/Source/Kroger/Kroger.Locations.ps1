function Find-KrogerStore
{
    <#
    .SYNOPSIS
    Finds Kroger stores near a location.

    .DESCRIPTION
    Searches for Kroger stores near a specified location using the Kroger Location API.
    Returns store information including location ID, address, and available services.

    .PARAMETER ZipCode
    Zip code to search for nearby stores.

    .PARAMETER Radius
    Search radius in miles (default: 10).

    .PARAMETER Chain
    Filter by chain name (e.g., 'Kroger', 'Fred Meyer', 'QFC').

    .PARAMETER Raw
    Return raw API response instead of custom objects.

    .EXAMPLE
    Find-KrogerStore -ZipCode '90210' -Radius 15

    .EXAMPLE
    Find-KrogerStore -ZipCode '90210' -Chain 'Kroger'

    .OUTPUTS
    Array of location objects with LocationId, Chain, Address, City, State, ZipCode properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ZipCode,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Radius = 10,

        [Parameter()]
        [string]$Chain,

        [Parameter()]
        [string[]]$Scope = @('product.compact'),

        [Parameter()]
        [switch]$Raw
    )

    begin
    {
        # Get authentication token
        Write-Verbose "Authenticating with Kroger API"
        $token = Connect-KrogerApi -Scope $Scope

        # Build API request headers
        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        # Build API endpoint
        $baseUrl = 'https://api.kroger.com/v1/locations'

        # Build query parameters
        $queryParams = @{
            'filter.zipCode.near'  = $ZipCode
            'filter.radiusInMiles' = $Radius
        }

        if ($Chain)
        {
            $queryParams['filter.chain'] = $Chain
        }

        Write-Verbose "Searching for Kroger stores near $ZipCode (radius: $Radius miles)"
    }

    process
    {
        try
        {
            # Build full URL with query parameters
            $queryString = ($queryParams.GetEnumerator() | ForEach-Object {
                    "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))"
                }) -join '&'

            $fullUrl = "$baseUrl`?$queryString"

            Write-Verbose "Request URL: $fullUrl"

            # Make API request
            $response = Invoke-WebApi -Method GET -Uri $fullUrl -Headers $headers

            if ($Raw)
            {
                return $response
            }

            # Convert API response to location objects
            if ($response.data -and $response.data.Count -gt 0)
            {
                $results = $response.data | ForEach-Object {
                    [PSCustomObject]@{
                        PSTypeName = 'Kroger.Location'
                        LocationId = $_.locationId
                        Chain      = $_.chain
                        Name       = $_.name
                        Address    = $_.addressLine1
                        City       = $_.city
                        State      = $_.state
                        ZipCode    = $_.zipCode
                        Phone      = $_.phoneNumber
                        Department = $_.departments -join ', '
                        Hours      = if ($_.hours) { $_.hours } else { $null }
                    }
                }

                Write-Verbose "Found $($results.Count) stores"
                return $results
            } else
            {
                Write-Verbose "No stores found"
                return @()
            }
        } catch
        {
            throw "Failed to find Kroger stores: $_"
        }
    }
}

function Set-KrogerDefaultLocation
{
    <#
    .SYNOPSIS
    Sets the default Kroger location for product searches.

    .DESCRIPTION
    Stores the default Kroger store location permanently using CLIXML storage.
    This location will be used for location-aware product searches.

    .PARAMETER LocationId
    Store location ID to set as default.

    .PARAMETER InputObject
    Store object from Find-KrogerStore (pipeline input).

    .EXAMPLE
    Find-KrogerStore -ZipCode '90210' | Where-Object { $_.City -eq 'Beverly Hills' } | Set-KrogerDefaultLocation

    .EXAMPLE
    Set-KrogerDefaultLocation -LocationId '123456789'

    .OUTPUTS
    None
    #>
    [CmdletBinding(DefaultParameterSetName = 'LocationId')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'LocationId')]
        [string]$LocationId,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject')]
        [object]$InputObject
    )

    process
    {
        try
        {
            # Handle pipeline input
            $targetLocationId = if ($PSCmdlet.ParameterSetName -eq 'InputObject')
            {
                if ($InputObject.LocationId)
                {
                    $InputObject.LocationId
                } elseif ($InputObject.locationId)
                {
                    $InputObject.locationId
                } else
                {
                    throw "InputObject does not contain a LocationId property"
                }
            } else
            {
                $LocationId
            }

            # Store configuration path
            $configPath = Join-Path -Path $HOME -ChildPath '.kroger_config.xml'

            # Create configuration object
            $config = @{
                DefaultLocationId = $targetLocationId
                UpdatedAt         = (Get-Date)
            }

            # Save to CLIXML
            $config | Export-Clixml -Path $configPath -Force

            Write-Verbose "Default Kroger location set to: $targetLocationId"
            Write-Host "Default Kroger location saved: $targetLocationId" -ForegroundColor Green
        } catch
        {
            throw "Failed to set default Kroger location: $_"
        }
    }
}

function Get-KrogerDefaultLocation
{
    <#
    .SYNOPSIS
    Gets the default Kroger location.

    .DESCRIPTION
    Retrieves the stored default Kroger store location ID.

    .EXAMPLE
    Get-KrogerDefaultLocation

    .OUTPUTS
    String containing the default location ID, or $null if not set.
    #>
    [CmdletBinding()]
    param()

    process
    {
        try
        {
            # Configuration storage path
            $configPath = Join-Path -Path $HOME -ChildPath '.kroger_config.xml'

            # Check if configuration exists
            if (-not (Test-Path $configPath))
            {
                Write-Verbose "No default Kroger location configured"
                return $null
            }

            # Load configuration
            $config = Import-Clixml -Path $configPath

            if ($config.DefaultLocationId)
            {
                Write-Verbose "Default Kroger location: $($config.DefaultLocationId)"
                return $config.DefaultLocationId
            } else
            {
                Write-Verbose "No default location ID found in configuration"
                return $null
            }
        } catch
        {
            Write-Verbose "Failed to get default Kroger location: $_"
            return $null
        }
    }
}

function Clear-KrogerDefaultLocation
{
    <#
    .SYNOPSIS
    Clears the default Kroger location.

    .DESCRIPTION
    Removes the stored default Kroger store location.

    .EXAMPLE
    Clear-KrogerDefaultLocation

    .OUTPUTS
    None
    #>
    [CmdletBinding()]
    param()

    process
    {
        try
        {
            # Configuration storage path
            $configPath = Join-Path -Path $HOME -ChildPath '.kroger_config.xml'

            # Check if configuration exists
            if (Test-Path $configPath)
            {
                Remove-Item -Path $configPath -Force
                Write-Verbose "Default Kroger location cleared"
                Write-Host "Default Kroger location removed" -ForegroundColor Yellow
            } else
            {
                Write-Verbose "No default Kroger location to clear"
            }
        } catch
        {
            throw "Failed to clear default Kroger location: $_"
        }
    }
}
