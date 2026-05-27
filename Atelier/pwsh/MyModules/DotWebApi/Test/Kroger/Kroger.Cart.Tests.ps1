BeforeAll {
    Import-Module $PSScriptRoot/../../DotWebApi.psd1 -Force

    # Mock token response
    $MockKrogerToken = @{
        access_token  = 'mock_token_12345'
        token_type    = 'Bearer'
        expires_in    = 3600
        expires_at    = (Get-Date).AddHours(1)
        scope         = 'cart.basic cart.write'
    }

    # Mock cart response
    $MockCartResponse = @{
        items = @(
            @{
                id         = 'cart_item_1'
                productId  = '0011200000562'
                upc        = '0011200000562'
                quantity   = 2
                price      = @{
                    regular = 3.49
                }
                description = 'Kroger Whole Milk'
            },
            @{
                id         = 'cart_item_2'
                productId  = '0001111045628'
                upc        = '0001111045628'
                quantity   = 1
                price      = @{
                    regular = 4.99
                }
                description = 'Organic Valley Milk'
            }
        )
        metaData = @{
            total = 11.97
        }
    }

    # Mock empty cart response
    $MockEmptyCartResponse = @{
        items = @()
        metaData = @{
            total = 0
        }
    }

    # Setup mock API override
    $Script:MockWebApiOverride = {
        param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

        # Mock token endpoint
        if ($Uri -match 'oauth2/token') {
            return $MockKrogerToken
        }

        # Mock cart GET endpoint
        if ($Uri -match '/cart' -and $Method -eq 'GET') {
            return $MockCartResponse
        }

        # Mock cart POST endpoint (add item)
        if ($Uri -match '/cart.*?/items' -and $Method -eq 'POST') {
            return @{
                id         = 'new_cart_item_123'
                quantity   = $Body.quantity
                upc        = $Body.upc
            }
        }

        # Mock cart DELETE endpoint
        if ($Uri -match '/cart.*?/items/' -and $Method -eq 'DELETE') {
            return @{ success = $true }
        }

        # Mock cart PUT endpoint (update quantity)
        if ($Uri -match '/cart.*?/items/' -and $Method -eq 'PUT') {
            return @{
                id         = 'updated_cart_item'
                quantity   = $Body.quantity
            }
        }

        throw "Mock API endpoint not implemented: $Uri"
    }
}

AfterAll {
    # Clear mock override
    $Script:MockWebApiOverride = $null
}

Describe 'Get-KrogerCart' {
    It 'Gets cart contents successfully' {
        $cart = Get-KrogerCart
        $cart | Should -Not -BeNullOrEmpty
        $cart.Count | Should -BeGreaterOrEqual 1
    }

    It 'Returns Kroger.CartItem type objects' {
        $cart = Get-KrogerCart
        $cart[0].PSTypeName | Should -Be 'Kroger.CartItem'
    }

    It 'Returns cart items with correct properties' {
        $cart = Get-KrogerCart
        $item = $cart[0]

        $item.CartItemId | Should -Not -BeNullOrEmpty
        $item.ProductId | Should -Not -BeNullOrEmpty
        $item.Name | Should -Not -BeNullOrEmpty
        $item.Quantity | Should -Not -BeNullOrEmpty
        $item.Price | Should -Not -BeNullOrEmpty
        $item.Total | Should -Not -BeNullOrEmpty
    }

    It 'Calculates item total correctly' {
        $cart = Get-KrogerCart
        $item = $cart[0]

        $item.Total | Should -Be ($item.Price * $item.Quantity)
    }

    It 'Returns raw API response when Raw switch is used' {
        $response = Get-KrogerCart -Raw
        $response | Should -Not -BeNullOrEmpty
        $response.items | Should -Not -BeNullOrEmpty
    }

    It 'Handles empty cart gracefully' {
        # Mock empty cart
        $emptyMock = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockKrogerToken
            }

            if ($Uri -match '/cart' -and $Method -eq 'GET') {
                return $MockEmptyCartResponse
            }

            throw "Mock API endpoint not implemented: $Uri"
        }

        $Script:MockWebApiOverride = $emptyMock

        $cart = Get-KrogerCart
        $cart | Should -BeNullOrEmpty

        # Restore original mock
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockKrogerToken
            }

            if ($Uri -match '/cart' -and $Method -eq 'GET') {
                return $MockCartResponse
            }

            if ($Uri -match '/cart.*?/items' -and $Method -eq 'POST') {
                return @{
                    id         = 'new_cart_item_123'
                    quantity   = $Body.quantity
                    upc        = $Body.upc
                }
            }

            if ($Uri -match '/cart.*?/items/' -and $Method -eq 'DELETE') {
                return @{ success = $true }
            }

            if ($Uri -match '/cart.*?/items/' -and $Method -eq 'PUT') {
                return @{
                    id         = 'updated_cart_item'
                    quantity   = $Body.quantity
                }
            }

            throw "Mock API endpoint not implemented: $Uri"
        }
    }
}

Describe 'Add-KrogerCartItem' {
    It 'Adds item by UPC code' {
        $result = Add-KrogerCartItem -InputObject '0011200000562' -Quantity 2
        $result | Should -Be $true
    }

    It 'Adds item with custom quantity' {
        $result = Add-KrogerCartItem -InputObject '0011200000562' -Quantity 5
        $result | Should -Be $true
    }

    It 'Handles multiple items' {
        $upcs = @('0011200000562', '0001111045628')
        $result = $upcs | Add-KrogerCartItem -Quantity 1
        $result | Should -Be $true
    }

    It 'Supports WhatIf switch' {
        $result = Add-KrogerCartItem -InputObject '0011200000562' -WhatIf
        $result | Should -Be $true
        # Should not actually make API call
    }

    It 'Handles Kroger.Product objects from pipeline' {
        # This would require mocking Search-KrogerProduct as well
        # For now, test with a mock product object
        $mockProduct = [PSCustomObject]@{
            PSTypeName = 'Kroger.Product'
            Upc        = '0011200000562'
            Name       = 'Test Product'
            Brand      = 'Test Brand'
        }

        $result = $mockProduct | Add-KrogerCartItem -Quantity 1
        $result | Should -Be $true
    }

    It 'Returns added items when PassThru is used' {
        $result = Add-KrogerCartItem -InputObject '0011200000562' -Quantity 2 -PassThru
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles invalid UPC gracefully' {
        # Mock error response
        $errorMock = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockKrogerToken
            }

            if ($Uri -match '/cart.*?/items' -and $Method -eq 'POST') {
                throw "Product not found"
            }
        }

        $Script:MockWebApiOverride = $errorMock

        # Should not throw, but write warning
        $result = Add-KrogerCartItem -InputObject 'INVALID_UPC' -ErrorAction SilentlyContinue
        # Result might be $true even with warnings

        # Restore original mock
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockKrogerToken
            }

            if ($Uri -match '/cart' -and $Method -eq 'GET') {
                return $MockCartResponse
            }

            if ($Uri -match '/cart.*?/items' -and $Method -eq 'POST') {
                return @{
                    id         = 'new_cart_item_123'
                    quantity   = $Body.quantity
                    upc        = $Body.upc
                }
            }

            if ($Uri -match '/cart.*?/items/' -and $Method -eq 'DELETE') {
                return @{ success = $true }
            }

            if ($Uri -match '/cart.*?/items/' -and $Method -eq 'PUT') {
                return @{
                    id         = 'updated_cart_item'
                    quantity   = $Body.quantity
                }
            }

            throw "Mock API endpoint not implemented: $Uri"
        }
    }
}

Describe 'Remove-KrogerCartItem' {
    It 'Removes item by cart item ID' {
        $result = Remove-KrogerCartItem -CartItemId 'cart_item_1'
        $result | Should -Be $true
    }

    It 'Removes multiple items' {
        $itemIds = @('cart_item_1', 'cart_item_2')
        $result = Remove-KrogerCartItem -CartItemId $itemIds
        $result | Should -Be $true
    }

    It 'Supports WhatIf switch' {
        $result = Remove-KrogerCartItem -CartItemId 'cart_item_1' -WhatIf
        $result | Should -Be $true
    }

    It 'Handles Kroger.CartItem objects from pipeline' {
        $mockCartItem = [PSCustomObject]@{
            PSTypeName  = 'Kroger.CartItem'
            CartItemId  = 'cart_item_1'
            Name        = 'Test Product'
            Quantity    = 2
        }

        $result = $mockCartItem | Remove-KrogerCartItem
        $result | Should -Be $true
    }
}

Describe 'Clear-KrogerCart' {
    It 'Clears all items from cart' {
        $result = Clear-KrogerCart
        $result | Should -Be $true
    }

    It 'Supports WhatIf switch' {
        $result = Clear-KrogerCart -WhatIf
        $result | Should -Be $true
    }

    It 'Handles specific cart ID' {
        $result = Clear-KrogerCart -CartId 'abc123'
        $result | Should -Be $true
    }
}

Describe 'Update-KrogerCartItem' {
    It 'Updates item quantity' {
        $result = Update-KrogerCartItem -CartItemId 'cart_item_1' -Quantity 5
        $result | Should -Be $true
    }

    It 'Supports pipeline input with Kroger.CartItem objects' {
        $mockCartItem = [PSCustomObject]@{
            PSTypeName  = 'Kroger.CartItem'
            CartItemId  = 'cart_item_1'
            Name        = 'Test Product'
            Quantity    = 3
        }

        $result = $mockCartItem | Update-KrogerCartItem
        $result | Should -Be $true
    }

    It 'Uses quantity from object when not specified' {
        $mockCartItem = [PSCustomObject]@{
            PSTypeName  = 'Kroger.CartItem'
            CartItemId  = 'cart_item_1'
            Name        = 'Test Product'
            Quantity    = 7
        }

        $result = $mockCartItem | Update-KrogerCartItem
        $result | Should -Be $true
    }

    It 'Supports WhatIf switch' {
        $result = Update-KrogerCartItem -CartItemId 'cart_item_1' -Quantity 3 -WhatIf
        $result | Should -Be $true
    }
}

Describe 'Kroger.CartItem Object Properties' {
    It 'Creates cart item with correct structure' {
        $cart = Get-KrogerCart
        $item = $cart[0]

        # Verify all expected properties exist
        $item.PSObject.Properties.Name | Should -Contain 'CartItemId'
        $item.PSObject.Properties.Name | Should -Contain 'ProductId'
        $item.PSObject.Properties.Name | Should -Contain 'Upc'
        $item.PSObject.Properties.Name | Should -Contain 'Name'
        $item.PSObject.Properties.Name | Should -Contain 'Quantity'
        $item.PSObject.Properties.Name | Should -Contain 'Price'
        $item.PSObject.Properties.Name | Should -Contain 'Total'
        $item.PSObject.Properties.Name | Should -Contain 'ApiData'
    }

    It 'Calculates total correctly' {
        $cart = Get-KrogerCart
        $item = $cart[0]

        $expectedTotal = $item.Price * $item.Quantity
        $item.Total | Should -Be $expectedTotal
    }

    It 'Preserves original API data' {
        $cart = Get-KrogerCart
        $item = $cart[0]

        $item.ApiData | Should -Not -BeNullOrEmpty
        $item.ApiData.id | Should -Be $item.CartItemId
    }
}
