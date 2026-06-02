function Get-KrogerCart {
    <#
    .SYNOPSIS
    Retrieves the current Kroger shopping cart.

    .DESCRIPTION
    Gets the contents of the current user's shopping cart from Kroger API.

    .PARAMETER CartId
    Optional cart ID. If not specified, uses the default cart.

    .PARAMETER Raw
    Return raw API response instead of custom objects.

    .EXAMPLE
    Get-KrogerCart

    .EXAMPLE
    Get-KrogerCart -CartId 'abc123' -Raw

    .OUTPUTS
    Array of Kroger.CartItem objects or raw API response.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$CartId,

        [Parameter()]
        [switch]$Raw
    )

    begin {
        Write-Verbose "Retrieving Kroger cart"

        # Check for user session first
        $userSession = Get-KrogerUserSession
        if ($userSession -and -not (Test-WebApiTokenExpired -Token $userSession.token)) {
            Write-Verbose "Using user authentication"
            $token = $userSession.token

            # Use user's cart if no specific cart ID provided
            if (-not $CartId -and $userSession.cartId) {
                $CartId = $userSession.cartId
                Write-Verbose "Using user's cart: $CartId"
            }
        }
        else {
            # Fall back to API credentials for anonymous cart
            Write-Verbose "No user session, creating anonymous cart"
            $token = Connect-KrogerApi -Scope @('cart.basic')

            if (-not $CartId) {
                Write-Host "Note: Creating anonymous cart (requires manual token for personal cart)" -ForegroundColor Yellow
            }
        }

        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
            'Content-Type' = 'application/json'
        }
    }

    process {
        try {
            # Note: Kroger API doesn't appear to support retrieving cart contents
            # This endpoint returns 404, suggesting it's not available
            Write-Warning "Retrieving cart contents is not supported by Kroger API"
            Write-Warning "You can view your cart by visiting Kroger's website or app"
            return @()
        }
        catch {
            throw "Failed to get Kroger cart: $_"
        }
    }
}

function Add-KrogerCartItem {
    <#
    .SYNOPSIS
    Adds items to the Kroger shopping cart.

    .DESCRIPTION
    Adds products to the current user's shopping cart. Supports pipeline input
    from Search-KrogerProduct for easy workflows.

    .PARAMETER InputObject
    Product information to add. Can be Kroger.Product objects, UPC codes, or product IDs.

    .PARAMETER Quantity
    Quantity to add (default: 1, max: 99).

    .PARAMETER CartId
    Optional cart ID. If not specified, uses the default cart.

    .PARAMETER PassThru
    Return added items instead of just success status.

    .EXAMPLE
    Search-KrogerProduct -SearchTerm 'milk' | Select-Object -First 1 | Add-KrogerCartItem

    .EXAMPLE
    Add-KrogerCartItem -InputObject '0011200000562' -Quantity 2

    .EXAMPLE
    '0011200000562', '0001111045628' | Add-KrogerCartItem -Quantity 1 -WhatIf

    .OUTPUTS
    Boolean success status or Kroger.CartItem objects if PassThru is specified.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object[]]$InputObject,

        [Parameter(Position = 1)]
        [ValidateRange(1, 99)]
        [int]$Quantity = 1,

        [Parameter()]
        [string]$CartId,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        Write-Verbose "Starting to add items to Kroger cart"

        # Check if we were called right after Connect-KrogerPkce (session in memory)
        if ($null -ne $Script:KrogerUserSession) {
            $sessionAge = (Get-Date) - $Script:KrogerUserSession.authenticatedAt
            if ($sessionAge.TotalMinutes -lt 5) {
                Write-Verbose "Using fresh in-memory session from recent Connect-KrogerPkce"
                $userSession = $Script:KrogerUserSession
            }
            else {
                Write-Verbose "In-memory session is too old ($($sessionAge.TotalMinutes) minutes old)"
                $userSession = $null
            }
        }

        # Try to get saved session
        if (-not $userSession) {
            Write-Verbose "Loading saved session from file"
            $userSession = Get-KrogerUserSession
        }

        if (-not $userSession) {
            throw "Cart operations require authentication. Please run: Connect-KrogerPkce"
        }

        if (Test-WebApiTokenExpired -Token $userSession.token) {
            Write-Verbose "User token expired, attempting refresh..."
            if (Update-KrogerUserToken) {
                $userSession = Get-KrogerUserSession
                if (-not $userSession) {
                    throw "Authentication expired. Please re-run: Connect-KrogerPkce"
                }
            }
            else {
                throw "Authentication expired. Please re-run: Connect-KrogerPkce"
            }
        }

        Write-Verbose "Using user authentication"
        $token = $userSession.token

        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
            'Content-Type' = 'application/json'
        }

        $addedItems = [System.Collections.Generic.List[object]]::new()
    }

    process {
        foreach ($item in $InputObject) {
            try {
                # Check if token needs refresh before each API call
                if ($userSession -and (Test-WebApiTokenExpired -Token $userSession.token)) {
                    Write-Verbose "Token expired during processing, refreshing..."
                    $refreshedSession = Get-KrogerUserSession
                    if ($refreshedSession) {
                        # Update the parent scope variables
                        Set-Variable -Name 'userSession' -Value $refreshedSession -Scope 1
                        Set-Variable -Name 'token' -Value $refreshedSession.token -Scope 1
                        $headers.Authorization = "Bearer $($refreshedSession.token.access_token)"
                    }
                    else {
                        Write-Warning "Token refresh failed, cannot continue adding items"
                        break
                    }
                }

                # Determine product ID from different input types
                if ($item -is [string]) {
                    # String input (UPC or product ID)
                    $productId = $item
                }
                elseif ($item.PSTypeName -eq 'Kroger.Product') {
                    # Kroger.Product object - use Upc property
                    $productId = $item.Upc
                }
                elseif ($item.PSTypeName -eq 'Kroger.CartItem') {
                    # Kroger.CartItem object - use Upc property
                    $productId = $item.Upc
                }
                elseif ($null -ne $item.upc -and $item.PSTypeName -notlike 'Kroger.*') {
                    # Object with upc property (but not a Kroger typed object)
                    $productId = $item.upc
                }
                elseif ($null -ne $item.ProductId) {
                    # Object with ProductId property
                    $productId = $item.ProductId
                }
                elseif ($null -ne $item.id) {
                    # Object with id property
                    $productId = $item.id
                }
                else {
                    throw "Cannot determine product ID from input: $item"
                }

                $itemDescription = if ($item.PSTypeName -eq 'Kroger.Product') {
                    $item.Name
                }
                elseif ($item -is [string]) {
                    $item
                }
                else {
                    $productId
                }

                if ($PSCmdlet.ShouldProcess($itemDescription, "Add $Quantity to cart")) {
                    $cartEndpoint = 'https://api.kroger.com/v1/cart/add'

                    $body = @{
                        items = @(
                            @{
                                upc      = $productId
                                quantity = $Quantity
                                modality = 'PICKUP'  # Default to pickup, could be parameterized
                            }
                        )
                    }

                    Write-Verbose "Adding item $productId (quantity: $Quantity) to cart"

                    $response = Invoke-WebApi -Method PUT -Uri $cartEndpoint -Headers $headers -Body $body

                    if ($PassThru) {
                        $addedItems.Add($response)
                    }

                    Write-Verbose "Successfully added item to cart"
                }
            }
            catch {
                Write-Warning "Failed to add item '$item' to cart: $_"
            }
        }
    }

    end {
        Write-Verbose "Completed adding items to cart"

        if ($PassThru) {
            return $addedItems
        }
        else {
            return $true
        }
    }
}

function Remove-KrogerCartItem {
    <#
    .SYNOPSIS
    Removes items from the Kroger shopping cart.

    .DESCRIPTION
    Removes specified items from the current user's shopping cart.

    .PARAMETER CartItemId
    Cart item ID(s) to remove.

    .PARAMETER CartId
    Optional cart ID. If not specified, uses the default cart.

    .PARAMETER InputObject
    Kroger.CartItem objects to remove (pipeline input).

    .EXAMPLE
    Remove-KrogerCartItem -CartItemId 'item123'

    .EXAMPLE
    Get-KrogerCart | Where-Object { $_.Name -like '*milk*' } | Remove-KrogerCartItem

    .OUTPUTS
    Boolean success status.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'CartItemId')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'CartItemId', Position = 0)]
        [string[]]$CartItemId,

        [Parameter()]
        [string]$CartId,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'PipelineInput')]
        [object[]]$InputObject
    )

    begin {
        Write-Verbose "Starting to remove items from Kroger cart"

        # Get authentication token
        $token = Connect-KrogerApi -Scope @('cart.basic:write')

        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
            'Content-Type' = 'application/json'
        }

        $itemsToRemove = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'PipelineInput') {
            foreach ($item in $InputObject) {
                # Extract cart item ID using if-elseif for mutual exclusivity
                if ($item.PSTypeName -eq 'Kroger.CartItem') {
                    $itemId = $item.CartItemId
                }
                elseif ($null -ne $item.CartItemId) {
                    $itemId = $item.CartItemId
                }
                elseif ($null -ne $item.id) {
                    $itemId = $item.id
                }
                else {
                    $itemId = $item
                }

                if ($itemId) {
                    $itemsToRemove.Add($itemId)
                }
            }
        }
        else {
            # CartItemId parameter set
            foreach ($itemId in $CartItemId) {
                $itemsToRemove.Add($itemId)
            }
        }
    }

    end {
        try {
            foreach ($itemId in $itemsToRemove) {
                if ($PSCmdlet.ShouldProcess($itemId, "Remove from cart")) {
                    $cartEndpoint = if ($CartId) {
                        "https://api.kroger.com/v1/cart/$CartId/items/$itemId"
                    }
                    else {
                        "https://api.kroger.com/v1/cart/items/$itemId"
                    }

                    Write-Verbose "Removing item $itemId from cart"

                    Invoke-WebApi -Method DELETE -Uri $cartEndpoint -Headers $headers

                    Write-Verbose "Successfully removed item $itemId from cart"
                }
            }

            Write-Verbose "Completed removing items from cart"
            return $true
        }
        catch {
            throw "Failed to remove items from Kroger cart: $_"
        }
    }
}

function Clear-KrogerCart {
    <#
    .SYNOPSIS
    Clears all items from the Kroger shopping cart.

    .DESCRIPTION
    Removes all items from the current user's shopping cart.

    .PARAMETER CartId
    Optional cart ID. If not specified, uses the default cart.

    .EXAMPLE
    Clear-KrogerCart

    .EXAMPLE
    Clear-KrogerCart -CartId 'abc123' -WhatIf

    .OUTPUTS
    Boolean success status.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$CartId
    )

    begin {
        Write-Verbose "Clearing Kroger cart"

        # Get authentication token
        $token = Connect-KrogerApi -Scope @('cart.basic:write')

        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
            'Content-Type' = 'application/json'
        }
    }

    process {
        try {
            $cartEndpoint = if ($CartId) {
                "https://api.kroger.com/v1/cart/$CartId"
            }
            else {
                'https://api.kroger.com/v1/cart'
            }

            if ($PSCmdlet.ShouldProcess($CartId ?? "default cart", "Clear all items")) {
                Write-Verbose "Clearing cart"

                # First get all items
                $cartItems = Get-KrogerCart -CartId $CartId

                # Remove each item individually
                foreach ($item in $cartItems) {
                    $itemEndpoint = if ($CartId) {
                        "https://api.kroger.com/v1/cart/$CartId/items/$($item.CartItemId)"
                    }
                    else {
                        "https://api.kroger.com/v1/cart/items/$($item.CartItemId)"
                    }

                    Invoke-WebApi -Method DELETE -Uri $itemEndpoint -Headers $headers
                }

                Write-Verbose "Successfully cleared cart"
                return $true
            }
        }
        catch {
            throw "Failed to clear Kroger cart: $_"
        }
    }
}

function Update-KrogerCartItem {
    <#
    .SYNOPSIS
    Updates quantity of items in the Kroger shopping cart.

    .DESCRIPTION
    Changes the quantity of existing items in the current user's shopping cart.

    .PARAMETER CartItemId
    Cart item ID to update.

    .PARAMETER Quantity
    New quantity (1-99).

    .PARAMETER CartId
    Optional cart ID. If not specified, uses the default cart.

    .PARAMETER InputObject
    Kroger.CartItem object to update (pipeline input).

    .EXAMPLE
    Update-KrogerCartItem -CartItemId 'item123' -Quantity 3

    .EXAMPLE
    Get-KrogerCart | Where-Object { $_.Name -like '*milk*' } | Update-KrogerCartItem -Quantity 2

    .OUTPUTS
    Boolean success status.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'CartItemId')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'CartItemId', Position = 0)]
        [string]$CartItemId,

        [Parameter(Mandatory, ParameterSetName = 'CartItemId', Position = 1)]
        [ValidateRange(1, 99)]
        [int]$Quantity,

        [Parameter()]
        [string]$CartId,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'PipelineInput')]
        [object[]]$InputObject,

        [Parameter(ParameterSetName = 'PipelineInput')]
        [ValidateRange(1, 99)]
        [int]$UpdateQuantity = 1
    )

    begin {
        Write-Verbose "Starting to update items in Kroger cart"

        # Get authentication token
        $token = Connect-KrogerApi -Scope @('cart.basic:write')

        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
            'Content-Type' = 'application/json'
        }
    }

    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'PipelineInput') {
                foreach ($item in $InputObject) {
                    # Extract cart item ID using if-elseif for mutual exclusivity
                    if ($item.PSTypeName -eq 'Kroger.CartItem') {
                        $itemId = $item.CartItemId
                    }
                    elseif ($null -ne $item.CartItemId) {
                        $itemId = $item.CartItemId
                    }
                    elseif ($null -ne $item.id) {
                        $itemId = $item.id
                    }
                    else {
                        throw "Cannot determine cart item ID"
                    }

                    $itemQuantity = if ($item.Quantity) {
                        $item.Quantity
                    }
                    else {
                        $UpdateQuantity
                    }

                    if ($PSCmdlet.ShouldProcess($itemId, "Update quantity to $itemQuantity")) {
                        $cartEndpoint = if ($CartId) {
                            "https://api.kroger.com/v1/cart/$CartId/items/$itemId"
                        }
                        else {
                            "https://api.kroger.com/v1/cart/items/$itemId"
                        }

                        $body = @{
                            quantity = $itemQuantity
                        }

                        Write-Verbose "Updating item $itemId quantity to $itemQuantity"

                        Invoke-WebApi -Method PUT -Uri $cartEndpoint -Headers $headers -Body $body

                        Write-Verbose "Successfully updated item $itemId"
                    }
                }
            }
            else {
                # CartItemId parameter set
                if ($PSCmdlet.ShouldProcess($CartItemId, "Update quantity to $Quantity")) {
                    $cartEndpoint = if ($CartId) {
                        "https://api.kroger.com/v1/cart/$CartId/items/$CartItemId"
                    }
                    else {
                        "https://api.kroger.com/v1/cart/items/$CartItemId"
                    }

                    $body = @{
                        quantity = $Quantity
                    }

                    Write-Verbose "Updating item $CartItemId quantity to $Quantity"

                    Invoke-WebApi -Method PUT -Uri $cartEndpoint -Headers $headers -Body $body

                    Write-Verbose "Successfully updated item $CartItemId"
                }
            }

            Write-Verbose "Completed updating items in cart"
            return $true
        }
        catch {
            throw "Failed to update items in Kroger cart: $_"
        }
    }
}
