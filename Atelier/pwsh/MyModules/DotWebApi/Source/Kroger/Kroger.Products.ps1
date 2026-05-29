function Connect-KrogerApi {
    <#
    .SYNOPSIS
    Connects to Kroger API and obtains OAuth2 token.

    .DESCRIPTION
    Authenticates with Kroger API using OAuth2 client credentials flow.
    Returns a token object that can be used for subsequent API calls.

    .PARAMETER Scope
    OAuth2 scope(s) to request. Default is 'product.compact'.

    .PARAMETER ForceRefresh
    Force token refresh even if cached token is valid.

    .PARAMETER ClientId
    OAuth2 client ID. Defaults to retrieving from secret store.

    .PARAMETER ClientSecret
    OAuth2 client secret. Defaults to retrieving from secret store.

    .EXAMPLE
    Connect-KrogerApi

    .EXAMPLE
    Connect-KrogerApi -Scope 'cart.basic cart.write' -ForceRefresh

    .EXAMPLE
    Connect-KrogerApi -ClientId 'test_client' -ClientSecret 'test_secret'

    .OUTPUTS
    PSObject with token information.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Scope = @('product.compact'),

        [Parameter()]
        [switch]$ForceRefresh,

        [Parameter()]
        [string]$ClientId = (Get-Secret -Name 'KrogerClientId' -AsPlainText -ErrorAction SilentlyContinue),

        [Parameter()]
        [string]$ClientSecret = (Get-Secret -Name 'KrogerApiKey' -AsPlainText -ErrorAction SilentlyContinue)
    )

    $tokenEndpoint = 'https://api.kroger.com/v1/connect/oauth2/token'

    try {
        $token = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint $tokenEndpoint -Scope $Scope -ForceRefresh:$ForceRefresh -ClientId $ClientId -ClientSecret $ClientSecret
        Write-Verbose "Successfully connected to Kroger API"
        return $token
    }
    catch {
        throw "Failed to connect to Kroger API: $_"
    }
}

function Search-KrogerProduct {
    <#
    .SYNOPSIS
    Searches for products in the Kroger API.

    .DESCRIPTION
    Performs product searches against the Kroger Products API with support for
    various filters, pagination, and flexible search terms.

    .PARAMETER SearchTerm
    The search term to find products.

    .PARAMETER ProductId
    Search by specific product ID(s).

    .PARAMETER Upc
    Search by UPC code(s).

    .PARAMETER Brand
    Filter by brand name.

    .PARAMETER Category
    Filter by category path.

    .PARAMETER LocationId
    Filter by specific store location ID.

    .PARAMETER PageSize
    Number of results per page (1-100, default: 25).

    .PARAMETER Page
    Page number for pagination (default: 1).

    .PARAMETER Raw
    Return raw API response instead of custom objects.

    .EXAMPLE
    Search-KrogerProduct -SearchTerm 'milk'

    .EXAMPLE
    Search-KrogerProduct -SearchTerm 'cereal' -Brand 'Kroger' -PageSize 50

    .EXAMPLE
    Search-KrogerProduct -Upc '0011200000562'

    .OUTPUTS
    Array of Kroger.Product objects or raw API response.
    #>
    [CmdletBinding(DefaultParameterSetName = 'SearchTerm')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'SearchTerm', Position = 0)]
        [string]$SearchTerm,

        [Parameter(Mandatory, ParameterSetName = 'ProductId')]
        [string[]]$ProductId,

        [Parameter(Mandatory, ParameterSetName = 'Upc')]
        [string[]]$Upc,

        [Parameter(ParameterSetName = 'SearchTerm')]
        [string]$Brand,

        [Parameter(ParameterSetName = 'SearchTerm')]
        [string]$Category,

        [Parameter()]
        [string]$LocationId,

        [Parameter()]
        [switch]$UseDefaultLocation,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$PageSize = 25,

        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page = 1,

        [Parameter()]
        [switch]$Raw
    )

    begin {
        # Handle default location logic
        if ($UseDefaultLocation -and -not $LocationId) {
            $defaultLocation = Get-KrogerDefaultLocation
            if ($defaultLocation) {
                $LocationId = $defaultLocation
                Write-Verbose "Using default location: $LocationId"
                Write-Host "Using default Kroger location" -ForegroundColor Cyan
            }
            else {
                Write-Warning "No default location set. Use Set-KrogerDefaultLocation to set one."
            }
        }

        # Get authentication token
        Write-Verbose "Authenticating with Kroger API"
        $token = Connect-KrogerApi -Scope @('product.compact')

        # Build API request headers
        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        # Build API endpoint
        $baseUrl = 'https://api.kroger.com/v1/products'

        # Build filter parameters
        $filters = @()

        switch ($PSCmdlet.ParameterSetName) {
            'SearchTerm' {
                $filters += "term:$SearchTerm"
                if ($Brand) {
                    $filters += "brand:$Brand"
                }
                if ($Category) {
                    $filters += "category:$Category"
                }
            }
            'ProductId' {
                $filters += "productId: $($ProductId -join ',')"
            }
            'Upc' {
                $filters += "upc: $($Upc -join ',')"
            }
        }

        if ($LocationId) {
            $filters += "locationId:$LocationId"
        }

        # Build query parameters
        $queryParams = @{
            'filter.term'        = if ($PSCmdlet.ParameterSetName -eq 'SearchTerm') { $SearchTerm } else { $null }
            'filter.brand'       = $Brand
            'filter.category'    = $Category
            'filter.locationId'  = $LocationId
            'filter.productId'   = if ($PSCmdlet.ParameterSetName -eq 'ProductId') { $ProductId -join ',' } else { $null }
            'filter.upc'         = if ($PSCmdlet.ParameterSetName -eq 'Upc') { $Upc -join ',' } else { $null }
            'pageSize'           = $PageSize
            'pageNumber'         = $Page
        }

        # Remove null values
        $queryParams = $queryParams.GetEnumerator().Where({ $_.Value })

        Write-Verbose "Searching Kroger products with filters: $($filters -join ', ')"
    }

    process {
        try {
            # Build full URL with query parameters
            $queryString = ($queryParams.GetEnumerator() | ForEach-Object {
                "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))"
            }) -join '&'

            $fullUrl = if ($queryString) {
                "$baseUrl`?$queryString"
            }
            else {
                $baseUrl
            }

            Write-Verbose "Request URL: $fullUrl"

            # Make API request using Invoke-WebApi
            $response = Invoke-WebApi -Method GET -Uri $fullUrl -Headers $headers

            if ($Raw) {
                return $response
            }

            # Convert API response to custom objects
            if ($response.data -and $response.data.Count -gt 0) {
                $results = $response.data | ForEach-Object {
                    ConvertTo-KrogerProduct -ApiData $_
                }

                Write-Verbose "Found $($results.Count) products"
                return $results
            }
            else {
                Write-Verbose "No products found"
                return @()
            }
        }
        catch {
            throw "Failed to search Kroger products: $_"
        }
    }

    end {
        # Clean up if needed
    }
}

function Get-KrogerProductDetails {
    <#
    .SYNOPSIS
    Gets detailed information for specific Kroger products.

    .DESCRIPTION
    Retrieves detailed product information for one or more products by ID or UPC.

    .PARAMETER ProductId
    Product ID(s) to retrieve details for.

    .PARAMETER Upc
    UPC code(s) to retrieve details for.

    .PARAMETER Raw
    Return raw API response instead of custom objects.

    .EXAMPLE
    Get-KrogerProductDetails -ProductId '0011200000562'

    .EXAMPLE
    Get-KrogerProductDetails -Upc '0001111045628', '0011200000562'

    .OUTPUTS
    Kroger.Product objects or raw API response.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ProductId')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ProductId')]
        [string[]]$ProductId,

        [Parameter(Mandatory, ParameterSetName = 'Upc')]
        [string[]]$Upc,

        [Parameter()]
        [switch]$Raw
    )

    if ($ProductId) {
        Search-KrogerProduct -ProductId $ProductId -Raw:$Raw
    }
    elseif ($Upc) {
        Search-KrogerProduct -Upc $Upc -Raw:$Raw
    }
}
