# Script-level variable for mock API override (used in testing)
$Script:MockWebApiOverride = $null

function Invoke-WebApi {
    <#
    .SYNOPSIS
    Invokes web API calls with consistent error handling and mock support.

    .DESCRIPTION
    Provides a wrapper around Invoke-RestMethod with consistent error handling,
    mock support for testing, and standardized response processing.

    .PARAMETER Method
    HTTP method (GET, POST, PUT, DELETE, etc.).

    .PARAMETER Uri
    The API endpoint URI.

    .PARAMETER Body
    Request body parameters.

    .PARAMETER Headers
    Additional headers to include with the request.

    .PARAMETER ContentType
    Content type for the request (default: application/json).

    .PARAMETER TimeoutSec
    Request timeout in seconds.

    .EXAMPLE
    Invoke-WebApi -Method GET -Uri 'https://api.example.com/users' -Headers @{ Authorization = 'Bearer token123' }

    .EXAMPLE
    Invoke-WebApi -Method POST -Uri 'https://api.example.com/data' -Body @{ name = 'Test' }

    .OUTPUTS
    Response object from the API call.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [hashtable]$Body,

        [Parameter()]
        [hashtable]$Headers,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter()]
        [int]$TimeoutSec = 30
    )

    # Check if we're in test mode with mock override
    if ($null -ne $Script:MockWebApiOverride) {
        Write-Verbose "Using mock API override"
        return & $Script:MockWebApiOverride @PSBoundParameters
    }

    # Build request parameters
    $requestParams = @{
        Method      = $Method
        Uri         = $Uri
        ContentType = $ContentType
        TimeoutSec  = $TimeoutSec
    }

    # Add headers if provided
    if ($Headers) {
        $requestParams.Headers = $Headers
    }

    # Add body if provided
    if ($Body) {
        # Convert body to JSON for methods that support it
        if ($Method -in @('POST', 'PUT', 'PATCH')) {
            $requestParams.Body = $Body | ConvertTo-Json -Depth 10 -Compress
        }
        else {
            # For GET requests, add as query parameters
            $queryString = ($Body.GetEnumerator() | ForEach-Object {
                "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))"
            }) -join '&'
            $requestParams.Uri = "$Uri`?$queryString"
        }
    }

    try {
        Write-Verbose "Invoking API call: $Method $Uri"
        $response = Invoke-RestMethod @requestParams -ErrorAction Stop
        Write-Verbose "API call successful"
        return $response
    }
    catch {
        # Enhanced error handling
        $errorDetails = if ($_.ErrorDetails) {
            try {
                $_.ErrorDetails.Message | ConvertFrom-Json
            }
            catch {
                @{ message = $_.ErrorDetails.Message }
            }
        }
        else {
            @{ message = $_.Exception.Message }
        }

        $errorMessage = "API call failed: $Method $Uri"
        if ($errorDetails.message) {
            $errorMessage += " - $($errorDetails.message)"
        }

        Write-Error $errorMessage
        throw $_
    }
}

function ConvertTo-KrogerProduct {
    <#
    .SYNOPSIS
    Converts Kroger API product data to custom KrogerProduct object.

    .DESCRIPTION
    Transforms raw Kroger API response data into a standardized custom object
    with consistent properties for pipeline operations.

    .PARAMETER ApiData
    Raw product data from Kroger API.

    .EXAMPLE
    $apiProduct | ConvertTo-KrogerProduct

    .OUTPUTS
    Custom PSCustomObject with Kroger.Product type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$ApiData
    )

    process {
        # Handle different API response formats
        $productItem = if ($ApiData.items -and $ApiData.items.Count -gt 0) {
            $ApiData.items[0]
        }
        else {
            $ApiData
        }

        [PSCustomObject]@{
            PSTypeName = 'Kroger.Product'
            ProductId  = $ApiData.productId
            Upc        = $ApiData.upc
            Name       = $ApiData.description
            Brand      = $ApiData.brand
            Category   = if ($ApiData.categories) { $ApiData.categories -join ' > ' } else { $null }
            Size       = if ($ApiData.size) { $ApiData.size } else { $null }
            Price      = if ($productItem.price) { $productItem.price.regular } else { $null }
            OnSale     = if ($productItem.price) { $productItem.price.promo -gt 0 } else { $false }
            SalePrice  = if ($productItem.price -and $productItem.price.promo -gt 0) { $productItem.price.promo } else { $null }
            InStock    = if ($productItem.stock) { $productItem.stock.level -eq 'IN_STOCK' } else { $false }
            Location   = if ($productItem.location) { $productItem.location } else { $null }
            ImageUrl   = if ($ApiData.images -and $ApiData.images.Count -gt 0) { $ApiData.images[0].size.medium } else { $null }
            ApiData    = $ApiData
        }
    }
}

function ConvertTo-KrogerCartItem {
    <#
    .SYNOPSIS
    Converts Kroger API cart data to custom KrogerCartItem object.

    .DESCRIPTION
    Transforms raw Kroger API cart response data into a standardized custom object.

    .PARAMETER ApiData
    Raw cart item data from Kroger API.

    .EXAMPLE
    $apiCartItem | ConvertTo-KrogerCartItem

    .OUTPUTS
    Custom PSCustomObject with Kroger.CartItem type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$ApiData
    )

    process {
        [PSCustomObject]@{
            PSTypeName  = 'Kroger.CartItem'
            CartItemId  = $ApiData.id
            ProductId   = $ApiData.productId
            Upc         = $ApiData.upc
            Name        = $ApiData.description
            Quantity    = $ApiData.quantity
            Price       = $ApiData.price.regular
            Total       = $ApiData.price.regular * $ApiData.quantity
            ApiData     = $ApiData
        }
    }
}
