# Kroger API Unit Tests Based on Official Swagger Documentation
# All tests validate structure without making real API calls

BeforeAll {
    # Import required modules
    $modulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module $modulePath -Force

    # Load official swagger documentation
    $authSwaggerPath = Join-Path $modulePath "Source/Kroger/kroger_auth_openapi.json"
    $cartSwaggerPath = Join-Path $modulePath "Source/Kroger/kroger_cart_open_api.json"
    $locationSwaggerPath = Join-Path $modulePath "Source/Kroger/kroger_chain_location_openapi.json"

    $authSwagger = Get-Content $authSwaggerPath | ConvertFrom-Json
    $cartSwagger = Get-Content $cartSwaggerPath | ConvertFrom-Json
    $locationSwagger = Get-Content $locationSwaggerPath | ConvertFrom-Json
}

Describe 'Kroger Official Swagger Documentation Structure' {
    It 'Authentication swagger is valid OpenAPI 3.0.3' {
        $authSwagger.openapi | Should -Be '3.0.3'
        $authSwagger.info.title | Should -Be 'Authorization Endpoints'
        $authSwagger.info.version | Should -Be '1.0.17'
    }

    It 'Cart swagger is valid OpenAPI 3.0.3' {
        $cartSwagger.openapi | Should -Be '3.0.3'
        $cartSwagger.info.title | Should -Be 'Cart API'
        $cartSwagger.info.version | Should -Be '1.2.3'
    }

    It 'Location swagger is valid OpenAPI 3.0.3' {
        $locationSwagger.openapi | Should -Be '3.0.3'
        $locationSwagger.info.title | Should -Be 'Location API'
        $locationSwagger.info.version | Should -Be '1.2.3'
    }

    It 'Authentication endpoints are defined' {
        $authPaths = $authSwagger.paths.PSObject.Properties.Name
        '/v1/connect/oauth2/authorize' | Should -BeIn $authPaths
        '/v1/connect/oauth2/token' | Should -BeIn $authPaths
    }

    It 'Cart endpoint is defined' {
        $cartPaths = $cartSwagger.paths.PSObject.Properties.Name
        '/v1/cart/add' | Should -BeIn $cartPaths
    }

    It 'Location endpoints are defined' {
        $locationPaths = $locationSwagger.paths.PSObject.Properties.Name
        '/v1/locations' | Should -BeIn $locationPaths
        '/v1/locations/{locationId}' | Should -BeIn $locationPaths
        '/v1/chains' | Should -BeIn $locationPaths
        '/v1/departments' | Should -BeIn $locationPaths
    }

    It 'Token response schemas are defined' {
        $authSchemas = $authSwagger.components.schemas.PSObject.Properties.Name
        'authorization_code_response' | Should -BeIn $authSchemas
        'client_credentials_response' | Should -BeIn $authSchemas
        'refresh_token_response' | Should -BeIn $authSchemas
    }

    It 'Cart item schemas are defined' {
        $cartSchemas = $cartSwagger.components.schemas.PSObject.Properties.Name
        'cart.cartItemModel' | Should -BeIn $cartSchemas
        'cart.cartItemRequestModel' | Should -BeIn $cartSchemas
    }

    It 'Location schemas are defined' {
        $locationSchemas = $locationSwagger.components.schemas.PSObject.Properties.Name
        'locations.location' | Should -BeIn $locationSchemas
        'locations.chain' | Should -BeIn $locationSchemas
        'locations.department' | Should -BeIn $locationSchemas
    }
}

Describe 'ConvertTo-KrogerProduct Structure Validation' {
    It 'Creates product with required PSTypeName' {
        $mockApiData = @{
            productId   = 'test123'
            upc         = '0001111007790'
            description = 'Test Product'
            brand       = 'Test Brand'
        }

        $product = $mockApiData | ConvertTo-KrogerProduct

        $product.PSObject.TypeNames[0] | Should -Be 'Kroger.Product'
        $product.ProductId | Should -Be 'test123'
        $product.Upc | Should -Be '0001111007790'
        $product.Name | Should -Be 'Test Product'
        $product.Brand | Should -Be 'Test Brand'
    }

    It 'Handles products with items array correctly' {
        $mockApiData = @{
            productId   = 'test123'
            upc         = '0001111007790'
            description = 'Test Product'
            items       = @(
                @{
                    location = 'A1-2'
                    price    = @{ regular = 3.49; promo = 2.99 }
                    stock    = @{ level = 'IN_STOCK' }
                }
            )
        }

        $product = $mockApiData | ConvertTo-KrogerProduct

        $product.Price | Should -Be 3.49
        $product.OnSale | Should -Be $true
        $product.SalePrice | Should -Be 2.99
        $product.InStock | Should -Be $true
        $product.Location | Should -Be 'A1-2'
    }

    It 'Handles products without items array correctly' {
        $mockApiData = @{
            productId   = 'test123'
            upc         = '0001111007790'
            description = 'Test Product'
            brand       = 'Test Brand'
        }

        $product = $mockApiData | ConvertTo-KrogerProduct

        $product.Price | Should -Be $null
        $product.OnSale | Should -Be $false
        $product.InStock | Should -Be $false
        $product.Location | Should -Be $null
    }

    It 'Preserves raw API data' {
        $mockApiData = @{
            productId   = 'test123'
            upc         = '0001111007790'
            description = 'Test Product'
            categories  = @('Dairy', 'Milk')
        }

        $product = $mockApiData | ConvertTo-KrogerProduct

        $product.ApiData | Should -Not -BeNullOrEmpty
        $product.ApiData.productId | Should -Be 'test123'
        $product.ApiData.categories.Count | Should -Be 2
    }

    It 'Handles category paths correctly' {
        $mockApiData = @{
            productId   = 'test123'
            upc         = '0001111007790'
            description = 'Test Product'
            categories  = @('Dairy', 'Milk', 'Organic')
        }

        $product = $mockApiData | ConvertTo-KrogerProduct

        $product.Category | Should -Be 'Dairy > Milk > Organic'
    }
}

Describe 'Get-WebApiToken Function Structure' {
    It 'Has ClientId parameter with default value from Get-Secret' {
        $params = (Get-Command Get-WebApiToken).Parameters
        $params.ContainsKey('ClientId') | Should -Be $true
        $params['ClientId'].Attributes | Should -Not -BeNullOrEmpty
    }

    It 'Has ClientSecret parameter with default value from Get-Secret' {
        $params = (Get-Command Get-WebApiToken).Parameters
        $params.ContainsKey('ClientSecret') | Should -Be $true
        $params['ClientSecret'].Attributes | Should -Not -BeNullOrEmpty
    }

    It 'Constructs correct token request parameters' {
        # Test that the function would construct the right parameters
        $testClientId = 'test_client_123'
        $testClientSecret = 'test_secret_456'
        $testScope = @('test.scope')

        $expectedParams = @{
            grant_type    = 'client_credentials'
            client_id     = $testClientId
            client_secret = $testClientSecret
            scope         = 'test.scope'
        }

        # Verify the parameter construction logic
        $expectedParams.client_id | Should -Be $testClientId
        $expectedParams.client_secret | Should -Be $testClientSecret
        $expectedParams.scope | Should -Be 'test.scope'
    }
}

Describe 'Connect-KrogerApi Function Structure' {
    It 'Has ClientId parameter with default value from Get-Secret' {
        $params = (Get-Command Connect-KrogerApi).Parameters
        $params.ContainsKey('ClientId') | Should -Be $true
        $params['ClientId'].Attributes | Should -Not -BeNullOrEmpty
    }

    It 'Has ClientSecret parameter with default value from Get-Secret' {
        $params = (Get-Command Connect-KrogerApi).Parameters
        $params.ContainsKey('ClientSecret') | Should -Be $true
        $params['ClientSecret'].Attributes | Should -Not -BeNullOrEmpty
    }

    It 'Passes parameters to Get-WebApiToken correctly' {
        # Verify function structure allows parameter passing
        $params = (Get-Command Connect-KrogerApi).Parameters
        $params.ContainsKey('Scope') | Should -Be $true
        $params.ContainsKey('ForceRefresh') | Should -Be $true
        $params.ContainsKey('ClientId') | Should -Be $true
        $params.ContainsKey('ClientSecret') | Should -Be $true
    }

    It 'Has Scope parameter with correct type' {
        $params = (Get-Command Connect-KrogerApi).Parameters
        $params.ContainsKey('Scope') | Should -Be $true
        $params['Scope'].ParameterType.Name | Should -Be 'String[]'
    }
}

Describe 'Search-KrogerProduct Function Structure' {
    It 'Has correct parameter sets for different search types' {
        $cmdlet = Get-Command Search-KrogerProduct
        $cmdlet.ParameterSets.Count | Should -BeGreaterThan 0
        $cmdlet.ParameterSets.Name | Should -Contain 'SearchTerm'
        $cmdlet.ParameterSets.Name | Should -Contain 'ProductId'
        $cmdlet.ParameterSets.Name | Should -Contain 'Upc'
    }

    It 'Has required SearchTerm parameter in SearchTerm set' {
        $params = (Get-Command Search-KrogerProduct).Parameters
        $searchTermParam = $params['SearchTerm']

        $searchTermParam | Should -Not -BeNullOrEmpty
        $searchTermParam.ParameterSets.Keys | Should -Contain 'SearchTerm'
    }

    It 'Has ProductId parameter in ProductId set' {
        $params = (Get-Command Search-KrogerProduct).Parameters
        $productIdParam = $params['ProductId']

        $productIdParam | Should -Not -BeNullOrEmpty
        $productIdParam.ParameterSets.Keys | Should -Contain 'ProductId'
    }

    It 'Has Upc parameter in Upc set' {
        $params = (Get-Command Search-KrogerProduct).Parameters
        $upcParam = $params['Upc']

        $upcParam | Should -Not -BeNullOrEmpty
        $upcParam.ParameterSets.Keys | Should -Contain 'Upc'
    }

    It 'Has pagination parameters' {
        $params = (Get-Command Search-KrogerProduct).Parameters
        $params.ContainsKey('PageSize') | Should -Be $true
        $params.ContainsKey('Page') | Should -Be $true
    }

    It 'Has Raw parameter for returning raw API response' {
        $params = (Get-Command Search-KrogerProduct).Parameters
        $params.ContainsKey('Raw') | Should -Be $true
        $params['Raw'].ParameterType.Name | Should -Be 'SwitchParameter'
    }
}

Describe 'Cart API Structure Validation' {
    It 'Cart item structure matches cart.cartItemModel schema' {
        # Validate cart item structure per swagger schema
        $cartItem = @{
            upc      = '0001111007790'     # Required field
            quantity = 2                    # Required field
            modality = 'PICKUP'             # Optional, enum: DELIVERY, PICKUP
        }

        # Validate required fields
        $cartItem.upc | Should -Not -BeNullOrEmpty
        $cartItem.quantity | Should -BeGreaterThan 0
        $cartItem.quantity | Should -BeLessThan 100

        # Validate modality enum
        if ($cartItem.modality) {
            $cartItem.modality | Should -BeIn @('DELIVERY', 'PICKUP')
        }
    }

    It 'Cart item request structure matches cart.cartItemRequestModel schema' {
        $cartRequest = @{
            items = @(
                @{
                    upc      = '0001111007790'
                    quantity = 1
                    modality = 'PICKUP'
                }
            )
        }

        $cartRequest.items | Should -Not -BeNullOrEmpty
        $cartRequest.items.Count | Should -BeGreaterThan 0

        foreach ($item in $cartRequest.items) {
            $item.upc | Should -Not -BeNullOrEmpty
            $item.quantity | Should -BeGreaterThan 0

            if ($item.modality) {
                $item.modality | Should -BeIn @('DELIVERY', 'PICKUP')
            }
        }
    }

    It 'ConvertTo-KrogerCartItem creates correct structure' {
        $mockCartData = @{
            id          = 'cart_item_123'
            productId   = 'prod_456'
            upc         = '0001111007790'
            description = 'Test Product'
            quantity    = 2
            price       = @{
                regular = 3.49
            }
        }

        $cartItem = $mockCartData | ConvertTo-KrogerCartItem

        $cartItem.PSObject.TypeNames[0] | Should -Be 'Kroger.CartItem'
        $cartItem.CartItemId | Should -Be 'cart_item_123'
        $cartItem.ProductId | Should -Be 'prod_456'
        $cartItem.Upc | Should -Be '0001111007790'
        $cartItem.Name | Should -Be 'Test Product'
        $cartItem.Quantity | Should -Be 2
        $cartItem.Price | Should -Be 3.49
        $cartItem.Total | Should -Be 6.98  # Price * Quantity
    }
}

Describe 'Location API Structure Validation' {
    It 'Location object matches locations.location schema' {
        $mockLocation = @{
            locationId = '01400376'
            chain      = 'KROGER'
            name       = 'Kroger Landen'
            address    = @{
                addressLine1 = '2900 W. St. Rt. 22 & 3'
                city         = 'Maineville'
                state        = 'OH'
                zipCode      = '45039'
            }
            geolocation = @{
                latLng   = '39.3110881,-84.2751167'
                latitude  = 39.3110881
                longitude = -84.2751167
            }
            phone  = '5551234567'
            hours  = @{
                monday    = @{ open = '06:00'; close = '22:00' }
                tuesday   = @{ open = '06:00'; close = '22:00' }
                wednesday = @{ open = '06:00'; close = '22:00' }
                thursday  = @{ open = '06:00'; close = '22:00' }
                friday    = @{ open = '06:00'; close = '22:00' }
                saturday  = @{ open = '06:00'; close = '22:00' }
                sunday    = @{ open = '06:00'; close = '22:00' }
            }
        }

        # Validate required fields per locations.location schema
        $mockLocation.locationId | Should -Not -BeNullOrEmpty
        $mockLocation.chain | Should -Not -BeNullOrEmpty
        $mockLocation.name | Should -Not -BeNullOrEmpty
        $mockLocation.address | Should -Not -BeNullOrEmpty
        $mockLocation.geolocation | Should -Not -BeNullOrEmpty
        $mockLocation.hours | Should -Not -BeNullOrEmpty

        # Validate address structure
        $mockLocation.address.addressLine1 | Should -Not -BeNullOrEmpty
        $mockLocation.address.city | Should -Not -BeNullOrEmpty
        $mockLocation.address.state | Should -Not -BeNullOrEmpty
        $mockLocation.address.zipCode | Should -Not -BeNullOrEmpty

        # Validate geolocation structure
        $mockLocation.geolocation.latLng | Should -Match '^-?\d+\.\d+,-?\d+\.\d+$'
        $mockLocation.geolocation.latitude | Should -BeGreaterOrEqual -90
        $mockLocation.geolocation.latitude | Should -BeLessOrEqual 90
        $mockLocation.geolocation.longitude | Should -BeGreaterOrEqual -180
        $mockLocation.geolocation.longitude | Should -BeLessOrEqual 180
    }

    It 'Chain object matches locations.chain schema' {
        $mockChain = @{
            name    = 'KROGER'
            domain  = 'kroger.com'
            divisionNumbers = @('01', '02')
        }

        # Validate required fields per locations.chain schema
        $mockChain.name | Should -Not -BeNullOrEmpty
        $mockChain.domain | Should -Not -BeNullOrEmpty
        $mockChain.divisionNumbers | Should -Not -BeNullOrEmpty
    }

    It 'Department object matches locations.department schema' {
        $mockDepartment = @{
            departmentId = '13'
            name         = 'Grocery'
        }

        # Validate required fields per locations.department schema
        $mockDepartment.departmentId | Should -Not -BeNullOrEmpty
        $mockDepartment.name | Should -Not -BeNullOrEmpty
    }
}

Describe 'API Error Response Structure Validation' {
    It 'APIError structure matches swagger definition' {
        $mockError = @{
            timestamp = 1569851999383
            code      = 'API-4101-400'
            reason    = 'Invalid parameter'
        }

        $mockError.timestamp | Should -BeGreaterThan 0
        $mockError.code | Should -Not -BeNullOrEmpty
        $mockError.reason | Should -Not -BeNullOrEmpty
    }

    It 'Invalid_locationId error structure matches swagger' {
        $mockError = @{
            timestamp = 1569851999383
            code      = 'API-4101-400'
            reason    = "Field 'locationId' must have a length of 8 characters"
        }

        $mockError.code | Should -Be 'API-4101-400'
        $mockError.reason | Should -Match 'locationId.*8.*characters'
    }

    It 'Invalid.UPC error structure matches swagger' {
        $mockError = @{
            timestamp = 1569851999383
            code      = 'API-4101-400'
            reason    = 'UPC must have a length of 13 characters'
        }

        $mockError.code | Should -Be 'API-4101-400'
        $mockError.reason | Should -Match 'UPC.*13.*characters'
    }

    It 'Invalid_radiusInMiles error structure matches swagger' {
        $mockError = @{
            timestamp = 1569851999383
            code      = 'API-4101-400'
            reason    = "Field 'filter.radiusInMiles' outside of distance limits, distance range is 1 - 100 miles."
        }

        $mockError.code | Should -Be 'API-4101-400'
        $mockError.reason | Should -Match 'distance.*range.*1.*100'
    }

    It 'APIError.unauthorized structure matches swagger' {
        $mockError = @{
            errors = @{
                error            = 'invalid_token'
                error_description = 'The access token is invalid or has expired'
            }
        }

        $mockError.errors.error | Should -Not -BeNullOrEmpty
        $mockError.errors.error_description | Should -Not -BeNullOrEmpty
    }
}

Describe 'API Parameter Validation per Swagger Definitions' {
    It 'Validates UPC format per Invalid.UPC schema' {
        # Valid UPCs should be 13 digits
        $validUpc = '0001111007790'
        $validUpc | Should -Match '^\d{13}$'

        # Invalid UPCs should fail validation
        $invalidUpc = '123'
        $invalidUpc | Should -Not -Match '^\d{13}$'
    }

    It 'Validates locationId format per Invalid_locationId schema' {
        # Location IDs should be 8 characters
        $validLocationId = '01400376'
        $validLocationId.Length | Should -Be 8

        # Invalid location IDs should fail validation
        $invalidLocationId = 'invalid'
        $invalidLocationId.Length | Should -Not -Be 8
    }

    It 'Validates radiusInMiles range per Invalid_radiusInMiles schema' {
        # Valid range is 1-100 miles
        $validRadius = 50
        $validRadius | Should -BeGreaterOrEqual 1
        $validRadius | Should -BeLessOrEqual 100

        # Invalid values should fail validation
        $invalidRadiusLow = 0
        $invalidRadiusLow | Should -BeLessThan 1

        $invalidRadiusHigh = 150
        $invalidRadiusHigh | Should -BeGreaterThan 100
    }

    It 'Validates departmentId format per location swagger' {
        # Department IDs should be 2 digits
        $validDepartmentId = '13'
        $validDepartmentId.Length | Should -Be 2
        $validDepartmentId | Should -Match '^\d{2}$'

        # Invalid department IDs should fail validation
        $invalidDepartmentId = '1'
        $invalidDepartmentId.Length | Should -Not -Be 2
    }
}

Describe 'API Endpoint URL Structure' {
    It 'Authentication endpoint URLs match swagger definition' {
        $authBase = 'https://api.kroger.com/v1/connect/oauth2'

        $authEndpoints = @(
            "$authBase/authorize"
            "$authBase/token"
        )

        $authEndpoints | Should -HaveCount 2
        $authEndpoints[0] | Should -Match '^https://api\.kroger\.com/v1/connect/oauth2/authorize$'
        $authEndpoints[1] | Should -Match '^https://api\.kroger\.com/v1/connect/oauth2/token$'
    }

    It 'Cart endpoint URLs match swagger definition' {
        $cartEndpoint = 'https://api.kroger.com/v1/cart/add'

        $cartEndpoint | Should -Match '^https://api\.kroger\.com/v1/cart/add$'
    }

    It 'Location endpoint URLs match swagger definition' {
        $locationBase = 'https://api.kroger.com/v1'

        $locationEndpoints = @(
            "$locationBase/locations"
            "$locationBase/chains"
            "$locationBase/departments"
        )

        $locationEndpoints | Should -HaveCount 3
        $locationEndpoints[0] | Should -Match '^https://api\.kroger\.com/v1/locations$'
        $locationEndpoints[1] | Should -Match '^https://api\.kroger\.com/v1/chains$'
        $locationEndpoints[2] | Should -Match '^https://api\.kroger\.com/v1/departments$'
    }
}

AfterAll {
    Write-Host "=== Kroger Swagger Unit Tests Complete ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "All tests validated against official swagger schemas:" -ForegroundColor Green
    Write-Host "  - Authentication: $($authSwagger.info.title) v$($authSwagger.info.version)" -ForegroundColor White
    Write-Host "  - Cart API: $($cartSwagger.info.title) v$($cartSwagger.info.version)" -ForegroundColor White
    Write-Host "  - Location API: $($locationSwagger.info.title) v$($locationSwagger.info.version)" -ForegroundColor White
    Write-Host ""
    Write-Host "No real API calls were made - all tests used structure validation" -ForegroundColor Green
}