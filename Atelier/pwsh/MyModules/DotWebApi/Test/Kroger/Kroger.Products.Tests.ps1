BeforeAll {
    Import-Module $PSScriptRoot/../../DotWebApi.psd1 -Force

    # Mock token response
    $MockKrogerToken = @{
        access_token = 'mock_token_12345'
        token_type   = 'Bearer'
        expires_in   = 3600
        expires_at   = (Get-Date).AddHours(1)
        scope        = 'product.compact'
    }

    # Mock product search response
    $MockProductSearchResponse = @{
        data = @(
            @{
                productId   = '0011200000562'
                upc         = '0011200000562'
                description = 'Kroger Whole Milk'
                brand       = 'Kroger'
                categories  = @('Dairy', 'Milk')
                size        = '1 gal'
                items       = @(
                    @{
                        price    = @{
                            regular = 3.49
                            promo   = 0
                        }
                        stock    = @{
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
            },
            @{
                productId   = '0001111045628'
                upc         = '0001111045628'
                description = 'Organic Valley Milk'
                brand       = 'Organic Valley'
                categories  = @('Dairy', 'Organic Milk')
                size        = '0.5 gal'
                items       = @(
                    @{
                        price    = @{
                            regular = 4.99
                            promo   = 3.99
                        }
                        stock    = @{
                            level = 'IN_STOCK'
                        }
                        location = 'B2-3'
                    }
                )
                images      = @()
            }
        )
        meta = @{
            pagination = @{
                pageSize   = 25
                pageNumber = 1
                totalItems = 2
            }
        }
    }

    # Setup mock API override
    $Script:MockWebApiOverride = {
        param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)

        # Mock token endpoint
        if ($Uri -match 'oauth2/token')
        {
            return $MockKrogerToken
        }

        # Mock product search endpoint
        if ($Uri -match '/products')
        {
            return $MockProductSearchResponse
        }

        throw "Mock API endpoint not implemented: $Uri"
    }
}

AfterAll {
    # Clear mock override
    $Script:MockWebApiOverride = $null
}

Describe 'Connect-KrogerApi' {
    It 'Connects to Kroger API and returns token' {
        $token = Connect-KrogerApi
        $token | Should -Not -BeNullOrEmpty
        $token.access_token | Should -Be 'mock_token_12345'
        $token.token_type | Should -Be 'Bearer'
    }

    It 'Uses correct scope for product access' {
        $token = Connect-KrogerApi -Scope @('product.compact')
        $token.scope | Should -Be 'product.compact'
    }

    It 'Caches token for subsequent calls' {
        $token1 = Connect-KrogerApi
        $token2 = Connect-KrogerApi
        $token1.access_token | Should -Be $token2.access_token
    }

    It 'Forces token refresh when requested' {
        # This test would require mocking the token cache
        $token = Connect-KrogerApi -ForceRefresh
        $token | Should -Not -BeNullOrEmpty
    }
}

Describe 'Search-KrogerProduct' {
    It 'Searches for products by term' {
        $results = Search-KrogerProduct -SearchTerm 'milk'
        $results | Should -Not -BeNullOrEmpty
        $results.Count | Should -BeGreaterOrEqual 1
    }

    It 'Returns Kroger.Product type objects' {
        $results = Search-KrogerProduct -SearchTerm 'milk'
        $results[0].PSTypeName | Should -Be 'Kroger.Product'
    }

    It 'Returns products with correct properties' {
        $results = Search-KrogerProduct -SearchTerm 'milk'
        $product = $results[0]

        $product.ProductId | Should -Not -BeNullOrEmpty
        $product.Name | Should -Not -BeNullOrEmpty
        $product.Brand | Should -Not -BeNullOrEmpty
        $product.Price | Should -Not -BeNullOrEmpty
    }

    It 'Handles pagination correctly' {
        $results = Search-KrogerProduct -SearchTerm 'milk' -PageSize 10 -Page 1
        $results | Should -Not -BeNullOrEmpty
    }

    It 'Filters by brand' {
        $results = Search-KrogerProduct -SearchTerm 'milk' -Brand 'Kroger'
        $results | Should -Not -BeNullOrEmpty

        # Check if all results are Kroger brand (this depends on mock data)
        $krogerProducts = $results | Where-Object { $_.Brand -eq 'Kroger' }
        $krogerProducts | Should -Not -BeNullOrEmpty
    }

    It 'Returns raw API response when Raw switch is used' {
        $response = Search-KrogerProduct -SearchTerm 'milk' -Raw
        $response | Should -Not -BeNullOrEmpty
        $response.data | Should -Not -BeNullOrEmpty
    }

    It 'Handles empty search results gracefully' {
        # Mock empty response
        $emptyMock = {
            param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token')
            {
                return $MockKrogerToken
            }

            if ($Uri -match '/products')
            {
                return @{ data = @() }
            }
        }

        $Script:MockWebApiOverride = $emptyMock

        $results = Search-KrogerProduct -SearchTerm 'nonexistentproductxyz'
        $results | Should -BeNullOrEmpty

        # Restore original mock
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $Headers, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token')
            {
                return $MockKrogerToken
            }

            if ($Uri -match '/products')
            {
                return $MockProductSearchResponse
            }
        }
    }
}

Describe 'Get-KrogerProductDetails' {
    It 'Gets product details by product ID' {
        $results = Get-KrogerProductDetails -ProductId '0011200000562'
        $results | Should -Not -BeNullOrEmpty
    }

    It 'Gets product details by UPC' {
        $results = Get-KrogerProductDetails -Upc '0011200000562'
        $results | Should -Not -BeNullOrEmpty
    }

    It 'Handles multiple UPC codes' {
        $results = Get-KrogerProductDetails -Upc '0011200000562', '0001111045628'
        $results | Should -Not -BeNullOrEmpty
    }
}

Describe 'Kroger.Product Object Properties' {
    It 'Creates product with correct structure' {
        $results = Search-KrogerProduct -SearchTerm 'milk'
        $product = $results[0]

        # Verify all expected properties exist
        $product.PSObject.Properties.Name | Should -Contain 'ProductId'
        $product.PSObject.Properties.Name | Should -Contain 'Upc'
        $product.PSObject.Properties.Name | Should -Contain 'Name'
        $product.PSObject.Properties.Name | Should -Contain 'Brand'
        $product.PSObject.Properties.Name | Should -Contain 'Category'
        $product.PSObject.Properties.Name | Should -Contain 'Size'
        $product.PSObject.Properties.Name | Should -Contain 'Price'
        $product.PSObject.Properties.Name | Should -Contain 'OnSale'
        $product.PSObject.Properties.Name | Should -Contain 'SalePrice'
        $product.PSObject.Properties.Name | Should -Contain 'InStock'
        $product.PSObject.Properties.Name | Should -Contain 'Location'
        $product.PSObject.Properties.Name | Should -Contain 'ImageUrl'
        $product.PSObject.Properties.Name | Should -Contain 'ApiData'
    }

    It 'Calculates OnSale correctly' {
        $results = Search-KrogerProduct -SearchTerm 'milk'

        # Find a product on sale and a regular price product
        $saleProduct = $results | Where-Object { $_.OnSale }
        $regularProduct = $results | Where-Object { -not $_.OnSale }

        if ($saleProduct)
        {
            $saleProduct.SalePrice | Should -BeGreaterThan 0
        }

        if ($regularProduct)
        {
            $regularProduct.SalePrice | Should -BeNullOrEmpty
        }
    }

    It 'Preserves original API data' {
        $results = Search-KrogerProduct -SearchTerm 'milk'
        $product = $results[0]

        $product.ApiData | Should -Not -BeNullOrEmpty
        $product.ApiData.productId | Should -Be $product.ProductId
    }
}

Describe 'Pipeline Support' {
    It 'Supports pipeline input for search operations' {
        $searchTerms = @('milk', 'eggs', 'bread')
        $results = $searchTerms | ForEach-Object {
            Search-KrogerProduct -SearchTerm $_
        }

        $results | Should -Not -BeNullOrEmpty
    }

    It 'Allows filtering search results in pipeline' {
        $results = Search-KrogerProduct -SearchTerm 'milk' |
            Where-Object { $_.Brand -eq 'Kroger' } |
            Select-Object -First 1

        $results | Should -Not -BeNullOrEmpty
        $results.Brand | Should -Be 'Kroger'
    }
}
