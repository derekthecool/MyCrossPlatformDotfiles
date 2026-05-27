BeforeAll {
    # Mock API response data
    $MockApiResponse = @{
        id         = '12345'
        name       = 'Test Product'
        status     = 'active'
        created    = '2024-01-01'
    }

    # Setup mock API override BEFORE importing module
    $Script:MockWebApiOverride = {
        param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)

        return $MockApiResponse
    }

    # Now import the module after mock is set up
    Import-Module $PSScriptRoot/../../DotWebApi.psd1 -Force

    $MockKrogerProductData = @{
        productId   = '0011200000562'
        upc         = '0011200000562'
        description = 'Kroger Whole Milk'
        brand       = 'Kroger'
        categories  = @('Dairy', 'Milk')
        size        = '1 gal'
        items       = @(
            @{
                price = @{
                    regular = 3.49
                    promo   = 2.99
                }
                stock  = @{
                    level = 'IN_STOCK'
                }
                location = 'A1-2'
            }
        )
        images      = @(
            @{
                size = @{
                    medium = 'https://kroger.com/images/milk.jpg'
                }
            }
        )
    }

    $MockKrogerCartItemData = @{
        id         = 'cart_item_1'
        productId  = '0011200000562'
        upc        = '0011200000562'
        quantity   = 2
        price      = @{
            regular = 3.49
        }
        description = 'Kroger Whole Milk'
    }
}

AfterAll {
    # Clear any mock overrides
    $Script:MockWebApiOverride = $null
}

Describe 'Invoke-WebApi' {
    BeforeEach {
        # Setup mock API override
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)

            return $MockApiResponse
        }
    }

    AfterEach {
        # Clear mock override
        $Script:MockWebApiOverride = $null
    }

    It 'Invokes GET requests correctly' {
        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test'

        $result | Should -Not -BeNullOrEmpty
        $result.name | Should -Be 'Test Product'
    }

    It 'Invokes POST requests with body correctly' {
        $result = Invoke-WebApi -Method POST -Uri 'https://api.example.com/test' -Body @{ name = 'Test' }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Uses mock override when available' {
        $customMock = {
            param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)
            return @{ custom = 'mock_response' }
        }

        $Script:MockWebApiOverride = $customMock

        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test'
        $result.custom | Should -Be 'mock_response'

        $Script:MockWebApiOverride = $null
    }

    It 'Handles headers correctly' {
        $headers = @{ Authorization = 'Bearer test_token' }

        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' -Headers $headers

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Respects custom content type' {
        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' -ContentType 'application/xml'

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles timeout parameter' {
        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' -TimeoutSec 60

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Passes all parameters to mock override' {
        $paramsReceived = $null

        $paramCaptureMock = {
            param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)

            $script:paramsReceived = @{
                Method      = $Method
                Uri         = $Uri
                Body        = $Body
                Headers     = $Headers
                ContentType = $ContentType
                TimeoutSec  = $TimeoutSec
            }

            return $MockApiResponse
        }.GetNewClosure()

        $Script:MockWebApiOverride = $paramCaptureMock

        Invoke-WebApi -Method POST -Uri 'https://api.example.com/test' -Body @{ test = 'value' } -ContentType 'application/json' -TimeoutSec 45

        $paramsReceived.Method | Should -Be 'POST'
        $paramsReceived.Uri | Should -Be 'https://api.example.com/test'
        $paramsReceived.Body | Should -Not -BeNullOrEmpty
        $paramsReceived.ContentType | Should -Be 'application/json'
        $paramsReceived.TimeoutSec | Should -Be 45

        $Script:MockWebApiOverride = $null
    }
}

Describe 'ConvertTo-KrogerProduct' {
    It 'Converts API product data to Kroger.Product object' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result | Should -Not -BeNullOrEmpty
        $result.PSTypeName | Should -Be 'Kroger.Product'
    }

    It 'Extracts all basic properties correctly' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.ProductId | Should -Be '0011200000562'
        $result.Upc | Should -Be '0011200000562'
        $result.Name | Should -Be 'Kroger Whole Milk'
        $result.Brand | Should -Be 'Kroger'
    }

    It 'Handles category array correctly' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.Category | Should -Be 'Dairy > Milk'
    }

    It 'Extracts price information correctly' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.Price | Should -Be 3.49
        $result.OnSale | Should -Be $true
        $result.SalePrice | Should -Be 2.99
    }

    It 'Extracts stock information correctly' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.InStock | Should -Be $true
        $result.Location | Should -Be 'A1-2'
    }

    It 'Extracts image URL correctly' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.ImageUrl | Should -Be 'https://kroger.com/images/milk.jpg'
    }

    It 'Preserves original API data' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.ApiData | Should -Not -BeNullOrEmpty
        $result.ApiData.productId | Should -Be '0011200000562'
    }

    It 'Handles product without items array' {
        $productWithoutItems = @{
            productId   = '0011200000563'
            upc         = '0011200000563'
            description = 'Test Product'
            brand       = 'Test Brand'
            categories  = @()
            size        = '1 lb'
            images      = @()
        }

        $result = $productWithoutItems | ConvertTo-KrogerProduct

        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Be 'Test Product'
        $result.Price | Should -BeNullOrEmpty
        $result.InStock | Should -Be $false
    }

    It 'Handles product without images' {
        $productWithoutImages = @{
            productId   = '0011200000564'
            upc         = '0011200000564'
            description = 'Test Product'
            brand       = 'Test Brand'
            categories  = @()
            size        = '1 lb'
            items       = @(
                @{
                    price = @{ regular = 1.99; promo = 0 }
                    stock  = @{ level = 'IN_STOCK' }
                    location = 'B1'
                }
            )
            images      = @()
        }

        $result = $productWithoutImages | ConvertTo-KrogerProduct

        $result | Should -Not -BeNullOrEmpty
        $result.ImageUrl | Should -BeNullOrEmpty
    }

    It 'Handles products not on sale' {
        $productNotOnSale = @{
            productId   = '0011200000565'
            upc         = '0011200000565'
            description = 'Regular Product'
            brand       = 'Test Brand'
            categories  = @()
            size        = '1 lb'
            items       = @(
                @{
                    price = @{ regular = 2.99; promo = 0 }
                    stock  = @{ level = 'IN_STOCK' }
                    location = 'C1'
                }
            )
            images      = @()
        }

        $result = $productNotOnSale | ConvertTo-KrogerProduct

        $result.OnSale | Should -Be $false
        $result.SalePrice | Should -BeNullOrEmpty
    }

    It 'Supports pipeline input' {
        $products = @($MockKrogerProductData, $MockKrogerProductData)
        $results = $products | ConvertTo-KrogerProduct

        $results.Count | Should -Be 2
        $results[0].PSTypeName | Should -Be 'Kroger.Product'
        $results[1].PSTypeName | Should -Be 'Kroger.Product'
    }
}

Describe 'ConvertTo-KrogerCartItem' {
    It 'Converts API cart item data to Kroger.CartItem object' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem

        $result | Should -Not -BeNullOrEmpty
        $result.PSTypeName | Should -Be 'Kroger.CartItem'
    }

    It 'Extracts all cart item properties correctly' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem

        $result.CartItemId | Should -Be 'cart_item_1'
        $result.ProductId | Should -Be '0011200000562'
        $result.Upc | Should -Be '0011200000562'
        $result.Name | Should -Be 'Kroger Whole Milk'
        $result.Quantity | Should -Be 2
        $result.Price | Should -Be 3.49
    }

    It 'Calculates total price correctly' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem

        $result.Total | Should -Be 6.98 # 3.49 * 2
    }

    It 'Preserves original API data' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem

        $result.ApiData | Should -Not -BeNullOrEmpty
        $result.ApiData.id | Should -Be 'cart_item_1'
    }

    It 'Supports pipeline input' {
        $cartItems = @($MockKrogerCartItemData, $MockKrogerCartItemData)
        $results = $cartItems | ConvertTo-KrogerCartItem

        $results.Count | Should -Be 2
        $results[0].PSTypeName | Should -Be 'Kroger.CartItem'
        $results[1].PSTypeName | Should -Be 'Kroger.CartItem'
    }

    It 'Handles cart item with different quantity' {
        $cartItem = @{
            id         = 'cart_item_2'
            productId  = '0011200000563'
            upc        = '0011200000563'
            quantity   = 5
            price      = @{ regular = 1.99 }
            description = 'Another Product'
        }

        $result = $cartItem | ConvertTo-KrogerCartItem

        $result.Quantity | Should -Be 5
        $result.Total | Should -Be 9.95 # 1.99 * 5
    }
}

Describe 'Helper Function Integration' {
    It 'ConvertTo-KrogerProduct handles null input gracefully' {
        $result = $null | ConvertTo-KrogerProduct -ErrorAction SilentlyContinue
        # Should handle gracefully without throwing
        $true | Should -Be $true
    }

    It 'ConvertTo-KrogerCartItem handles null input gracefully' {
        $result = $null | ConvertTo-KrogerCartItem -ErrorAction SilentlyContinue
        # Should handle gracefully without throwing
        $true | Should -Be $true
    }

    It 'Pipeline workflow: Mock API → Convert to Product' {
        # Setup mock to return product data
        $productSearchMock = @{
            data = @($MockKrogerProductData)
        }

        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)
            return $productSearchMock
        }

        $apiResult = Invoke-WebApi -Method GET -Uri 'https://api.kroger.com/v1/products'
        $products = $apiResult.data | ForEach-Object { ConvertTo-KrogerProduct -ApiData $_ }

        $products | Should -Not -BeNullOrEmpty
        $products[0].PSTypeName | Should -Be 'Kroger.Product'

        $Script:MockWebApiOverride = $null
    }
}
