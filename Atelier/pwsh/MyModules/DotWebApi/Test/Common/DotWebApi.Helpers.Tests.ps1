BeforeAll {
    Import-Module $PSScriptRoot/../../DotWebApi.psd1 -Force

    # Mock API response data
    $MockApiResponse = @{
        id      = '12345'
        name    = 'Test Product'
        status  = 'active'
        created = '2024-01-01'
    }

    $MockKrogerProductData = @{
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
                    promo   = 2.99
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
    }

    $MockKrogerCartItemData = @{
        id          = 'cart_item_1'
        productId   = '0011200000562'
        upc         = '0011200000562'
        quantity    = 2
        price       = @{
            regular = 3.49
        }
        description = 'Kroger Whole Milk'
    }
}

Describe 'Invoke-WebApi' {
    BeforeEach {
        # Mock the actual HTTP call inside the module so no real network
        # traffic happens. The legacy $Script:MockWebApiOverride mechanism
        # was scoped to the test's script scope and never reached the
        # module's $Script: scope, so it silently did nothing.
        Mock Invoke-RestMethod { $MockApiResponse } -ModuleName DotWebApi
    }

    It 'Invokes GET requests correctly' {
        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test'

        $result | Should -Not -BeNullOrEmpty
        $result.name | Should -Be 'Test Product'
        Should -Invoke Invoke-RestMethod -Times 1 -ModuleName DotWebApi
    }

    It 'Invokes POST requests with body correctly' {
        $result = Invoke-WebApi -Method POST -Uri 'https://api.example.com/test' -Body @{ name = 'Test' }

        $result | Should -Not -BeNullOrEmpty
        $result.id | Should -Be '12345'
    }

    It 'Returns custom response when mock is customized' {
        Mock Invoke-RestMethod { @{ custom = 'mock_response' } } -ModuleName DotWebApi

        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test'
        $result.custom | Should -Be 'mock_response'
    }

    It 'Handles headers correctly' {
        $headers = @{ Authorization = 'Bearer test_token' }

        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' -Headers $headers

        $result | Should -Not -BeNullOrEmpty
        Should -Invoke Invoke-RestMethod -Times 1 -ModuleName DotWebApi -ParameterFilter { $Headers.Authorization -eq 'Bearer test_token' }
    }

    It 'Respects custom content type' {
        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' -ContentType 'application/xml'

        $result | Should -Not -BeNullOrEmpty
        Should -Invoke Invoke-RestMethod -Times 1 -ModuleName DotWebApi -ParameterFilter { $ContentType -eq 'application/xml' }
    }

    It 'Handles timeout parameter' {
        $result = Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' -TimeoutSec 60

        $result | Should -Not -BeNullOrEmpty
        Should -Invoke Invoke-RestMethod -Times 1 -ModuleName DotWebApi -ParameterFilter { $TimeoutSec -eq 60 }
    }

    It 'Passes body and method through to Invoke-RestMethod on POST' {
        Invoke-WebApi -Method POST -Uri 'https://api.example.com/test' -Body @{ test = 'value' } -ContentType 'application/json' -TimeoutSec 45

        Should -Invoke Invoke-RestMethod -Times 1 -ModuleName DotWebApi -ParameterFilter {
            $Method -eq 'POST' -and
            $Uri -eq 'https://api.example.com/test' -and
            $Body -ne $null -and
            $ContentType -eq 'application/json' -and
            $TimeoutSec -eq 45
        }
    }

    It 'Formats GET body as query string' {
        Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' -Body @{ filter = 'active' }

        Should -Invoke Invoke-RestMethod -Times 1 -ModuleName DotWebApi -ParameterFilter {
            $Uri -match '\?filter=active'
        }
    }

    It 'Throws a wrapped error when Invoke-RestMethod fails' {
        Mock Invoke-RestMethod { throw [System.Net.Http.HttpRequestException]::new('boom') } -ModuleName DotWebApi

        { Invoke-WebApi -Method GET -Uri 'https://api.example.com/test' } | Should -Throw
    }
}

Describe 'ConvertTo-KrogerProduct' {
    It 'Adds Kroger.Product TypeName' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result | Should -Not -BeNullOrEmpty
        $result.PSTypeNames | Should -Contain 'Kroger.Product'
    }

    It 'Preserves raw productId' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct
        $result.productId | Should -Be '0011200000562'
    }

    It 'Preserves raw upc' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct
        $result.upc | Should -Be '0011200000562'
    }

    It 'Preserves raw description' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct
        $result.description | Should -Be 'Kroger Whole Milk'
    }

    It 'Preserves raw brand' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct
        $result.brand | Should -Be 'Kroger'
    }

    It 'Preserves raw categories array' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct
        $result.categories.Count | Should -Be 2
        $result.categories -join ',' | Should -Be 'Dairy,Milk'
    }

    It 'Preserves nested items array including price and stock' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.items.Count | Should -Be 1
        $result.items[0].price.regular | Should -Be 3.49
        $result.items[0].price.promo | Should -Be 2.99
        $result.items[0].stock.level | Should -Be 'IN_STOCK'
        $result.items[0].location | Should -Be 'A1-2'
    }

    It 'Preserves nested images array' {
        $result = $MockKrogerProductData | ConvertTo-KrogerProduct

        $result.images.Count | Should -Be 1
        $result.images[0].size.medium | Should -Be 'https://kroger.com/images/milk.jpg'
    }

    It 'Supports pipeline input' {
        $products = @($MockKrogerProductData, $MockKrogerProductData)
        $results = $products | ConvertTo-KrogerProduct

        $results.Count | Should -Be 2
        $results[0].PSTypeNames | Should -Contain 'Kroger.Product'
        $results[1].PSTypeNames | Should -Contain 'Kroger.Product'
    }

    It 'Handles product without items or images arrays' {
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
        $result.PSTypeNames | Should -Contain 'Kroger.Product'
        $result.description | Should -Be 'Test Product'
        # Functions that preserve raw structure do not synthesize defaults;
        # missing properties are simply absent.
        $result.PSObject.Properties.Name -contains 'items' | Should -Be $false
    }
}

Describe 'ConvertTo-KrogerCartItem' {
    It 'Adds Kroger.CartItem TypeName' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem

        $result | Should -Not -BeNullOrEmpty
        $result.PSTypeNames | Should -Contain 'Kroger.CartItem'
    }

    It 'Preserves raw id' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem
        $result.id | Should -Be 'cart_item_1'
    }

    It 'Preserves raw productId and upc' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem
        $result.productId | Should -Be '0011200000562'
        $result.upc | Should -Be '0011200000562'
    }

    It 'Preserves raw description' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem
        $result.description | Should -Be 'Kroger Whole Milk'
    }

    It 'Preserves raw quantity' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem
        $result.quantity | Should -Be 2
    }

    It 'Preserves nested price hashtable' {
        $result = $MockKrogerCartItemData | ConvertTo-KrogerCartItem
        $result.price.regular | Should -Be 3.49
    }

    It 'Supports pipeline input' {
        $cartItems = @($MockKrogerCartItemData, $MockKrogerCartItemData)
        $results = $cartItems | ConvertTo-KrogerCartItem

        $results.Count | Should -Be 2
        $results[0].PSTypeNames | Should -Contain 'Kroger.CartItem'
        $results[1].PSTypeNames | Should -Contain 'Kroger.CartItem'
    }
}

Describe 'Helper Function Integration' {
    It 'Pipeline workflow: Mock API → Convert to Product' {
        $productSearchResponse = @{ data = @($MockKrogerProductData) }
        Mock Invoke-RestMethod { $productSearchResponse } -ModuleName DotWebApi

        $apiResult = Invoke-WebApi -Method GET -Uri 'https://api.kroger.com/v1/products'
        $products = $apiResult.data | ForEach-Object { ConvertTo-KrogerProduct -ApiData $_ }

        $products | Should -Not -BeNullOrEmpty
        $products[0].PSTypeNames | Should -Contain 'Kroger.Product'
        $products[0].productId | Should -Be '0011200000562'
    }
}
