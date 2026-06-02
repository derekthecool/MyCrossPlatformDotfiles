# Kroger API Swagger-Based Integration Tests
# Tests based on official Kroger API swagger documentation
# These tests can run against the real API when credentials are available

BeforeAll {
    # Import required modules
    $modulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module $modulePath -Force

    # Load swagger documentation
    $swaggerPath = Join-Path $modulePath "Swagger/kroger-api.swagger.json"
    $swaggerDefinition = Get-Content $swaggerPath | ConvertFrom-Json

    # Check if we have API credentials
    $hasApiCredentials = $false
    try
    {
        $clientId = Get-Secret -Name 'KrogerClientId' -AsPlainText -ErrorAction Stop
        $clientSecret = Get-Secret -Name 'KrogerApiKey' -AsPlainText -ErrorAction Stop
        if ($clientId -and $clientSecret)
        {
            $hasApiCredentials = $true
        }
    } catch
    {
        $hasApiCredentials = $false
    }

    # Check if running in CI
    $isCI = $env:CI -eq 'true'
}

Describe 'Kroger API Swagger Validation' {
    It 'Swagger file exists and is valid JSON' {
        $swaggerPath | Should -Exist
        { Get-Content $swaggerPath | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'Swagger definition contains required OpenAPI fields' {
        $swaggerDefinition.openapi | Should -Not -BeNullOrEmpty
        $swaggerDefinition.info.title | Should -Be 'Kroger API'
        $swaggerDefinition.servers | Should -Not -BeNullOrEmpty
        $swaggerDefinition.paths | Should -Not -BeNullOrEmpty
    }

    It 'Swagger defines all major API endpoints' {
        $paths = $swaggerDefinition.paths.PSObject.Properties.Name

        # Authentication endpoint
        '/connect/oauth2/token' | Should -BeIn $paths

        # Products endpoint
        '/products' | Should -BeIn $paths

        # Cart endpoints
        '/cart' | Should -BeIn $paths
        '/cart/add' | Should -BeIn $paths
        '/cart/items/{itemId}' | Should -BeIn $paths

        # Profile endpoint
        '/profile' | Should -BeIn $paths
    }

    It 'Swagger defines required data schemas' {
        $schemas = $swaggerDefinition.components.schemas.PSObject.Properties.Name

        'TokenResponse' | Should -BeIn $schemas
        'Product' | Should -BeIn $schemas
        'CartItem' | Should -BeIn $schemas
        'UserProfile' | Should -BeIn $schemas
        'Error' | Should -BeIn $schemas
    }
}

Describe 'Kroger API Authentication Endpoints' -Skip:(-not $hasApiCredentials -or $isCI) {
    It 'POST /connect/oauth2/token returns valid token response' {
        # Get API credentials
        $clientId = Get-Secret -Name 'KrogerClientId' -AsPlainText
        $clientSecret = Get-Secret -Name 'KrogerApiKey' -AsPlainText

        # Test client credentials grant
        $body = @{
            grant_type    = 'client_credentials'
            client_id     = $clientId
            client_secret = $clientSecret
            scope         = 'product.compact'
        }

        $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/connect/oauth2/token' `
            -Method Post `
            -Body $body `
            -ErrorAction Stop

        # Validate response matches swagger schema
        $response.access_token | Should -Not -BeNullOrEmpty
        $response.token_type | Should -Be 'Bearer'
        $response.expires_in | Should -BeGreaterThan 0

        # Token should be a string
        $response.access_token | Should -BeOfType string
    }

    It 'Token response includes required fields per swagger definition' {
        $token = Connect-KrogerApi -Scope @('product.compact')

        # Test that token matches TokenResponse schema
        $token.PSObject.Properties.Name | Should -Contain 'access_token'
        $token.PSObject.Properties.Name | Should -Contain 'token_type'
        $token.PSObject.Properties.Name | Should -Contain 'expires_in'

        $token.token_type | Should -Be 'Bearer'
        $token.expires_in | Should -BeGreaterThan 0
    }
}

Describe 'Kroger Products API Endpoints' -Skip:(-not $hasApiCredentials -or $isCI) {
    BeforeAll {
        $token = Connect-KrogerApi -Scope @('product.compact')
    }

    It 'GET /products with search term returns valid response' {
        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        $params = @{
            'filter.term' = 'milk'
            pageSize      = 5
            pageNumber    = 1
        }

        $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/products' `
            -Method Get `
            -Headers $headers `
            -Body $params `
            -ErrorAction Stop

        # Response should have data array
        $response.data | Should -Not -BeNullOrEmpty
        $response.data | Should -BeOfType System.Array

        # If results exist, they should match Product schema
        if ($response.data.Count -gt 0)
        {
            $firstProduct = $response.data[0]
            $firstProduct.PSObject.Properties.Name | Should -Contain 'productId'
            $firstProduct.PSObject.Properties.Name | Should -Contain 'upc'
            $firstProduct.PSObject.Properties.Name | Should -Contain 'description'
        }
    }

    It 'GET /products with UPC filter returns specific products' {
        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        # Test with a common UPC
        $params = @{
            'filter.upc' = '0001111007790'  # Common milk UPC
            pageSize     = 10
        }

        $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/products' `
            -Method Get `
            -Headers $headers `
            -Body $params `
            -ErrorAction Stop

        # Response should contain products
        $response.data | Should -Not -BeNullOrEmpty

        # Products should have UPC matching search
        foreach ($product in $response.data)
        {
            $product.upc | Should -Be '0001111007790'
        }
    }

    It 'GET /products supports pagination parameters' {
        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        $params = @{
            'filter.term' = 'bread'
            pageSize      = 2
            pageNumber    = 1
        }

        $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/products' `
            -Method Get `
            -Headers $headers `
            -Body $params `
            -ErrorAction Stop

        # Should respect page size
        $response.data.Count | Should -BeLessOrEqual 2

        # Should have pagination metadata
        $response.meta | Should -Not -BeNullOrEmpty
        $response.meta.pageNumber | Should -Be 1
        $response.meta.pageSize | Should -Be 2
    }

    It 'GET /products supports brand filtering' {
        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        $params = @{
            'filter.term'  = 'milk'
            'filter.brand' = 'Kroger'
            pageSize       = 5
        }

        $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/products' `
            -Method Get `
            -Headers $headers `
            -Body $params `
            -ErrorAction Stop

        # If results exist, they should be Kroger brand
        if ($response.data.Count -gt 0)
        {
            foreach ($product in $response.data)
            {
                $product.brand | Should -Be 'Kroger'
            }
        }
    }
}

Describe 'Kroger Cart API Endpoints' -Skip:(-not $hasApiCredentials -or $isCI) {
    BeforeAll {
        # Check if we have user authentication
        $userSession = Get-KrogerUserSession
        $hasUserAuth = $null -ne $userSession -and -not (Test-WebApiTokenExpired -Token $userSession.token)
    }

    It 'PUT /cart/add requires user authentication' {
        # This should fail without user authentication
        $token = Connect-KrogerApi -Scope @('cart.basic')

        $headers = @{
            Authorization  = "Bearer $($token.access_token)"
            'Accept'       = 'application/json'
            'Content-Type' = 'application/json'
        }

        $body = @{
            items = @(
                @{
                    upc      = '0001111007790'
                    quantity = 1
                    modality = 'PICKUP'
                }
            )
        } | ConvertTo-Json

        # Should fail without proper user authentication
        { Invoke-RestMethod -Uri 'https://api.kroger.com/v1/cart/add' `
                -Method Put `
                -Headers $headers `
                -Body $body } | Should -Throw
    }

    It 'Cart endpoint follows swagger error response schema' -Skip:(-not $hasUserAuth) {
        # Test that error responses match Error schema
        $userSession = Get-KrogerUserSession
        $token = $userSession.token

        $headers = @{
            Authorization  = "Bearer $($token.access_token)"
            'Accept'       = 'application/json'
            'Content-Type' = 'application/json'
        }

        # Try to get cart contents (should fail with proper error format)
        try
        {
            $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/cart' `
                -Method Get `
                -Headers $headers `
                -ErrorAction Stop
        } catch
        {
            # Error response should match Error schema
            if ($_.ErrorDetails)
            {
                $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
                $errorResponse.PSObject.Properties.Name | Should -Contain 'error'
            }
        }
    }
}

Describe 'Kroger Profile API Endpoints' -Skip:(-not $hasApiCredentials -or $isCI) {
    BeforeAll {
        # Check if we have user authentication
        $userSession = Get-KrogerUserSession
        $hasUserAuth = $null -ne $userSession -and -not (Test-WebApiTokenExpired -Token $userSession.token)
    }

    It 'GET /profile returns user profile matching schema' -Skip:(-not $hasUserAuth) {
        $userSession = Get-KrogerUserSession
        $token = $userSession.token

        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/profile' `
            -Method Get `
            -Headers $headers `
            -ErrorAction Stop

        # Response should match UserProfile schema
        $response.PSObject.Properties.Name | Should -Contain 'id'
        $response.PSObject.Properties.Name | Should -Contain 'name'

        # ID should be a string
        $response.id | Should -BeOfType string
        $response.name | Should -Not -BeNullOrEmpty
    }

    It 'Profile API requires authentication' {
        # Test without authentication
        $headers = @{
            'Accept' = 'application/json'
        }

        { Invoke-RestMethod -Uri 'https://api.kroger.com/v1/profile' `
                -Method Get `
                -Headers $headers } | Should -Throw
    }
}

Describe 'Kroger PowerShell API Functions' -Skip:(-not $hasApiCredentials -or $isCI) {
    It 'Connect-KrogerApi returns valid token per swagger schema' {
        $token = Connect-KrogerApi -Scope @('product.compact')

        # Matches TokenResponse schema
        $token.PSObject.Properties.Name | Should -Contain 'access_token'
        $token.PSObject.Properties.Name | Should -Contain 'token_type'
        $token.PSObject.Properties.Name | Should -Contain 'expires_in'

        $token.token_type | Should -Be 'Bearer'
    }

    It 'Search-KrogerProduct returns products matching Product schema' {
        $results = Search-KrogerProduct -SearchTerm 'milk' -PageSize 5

        # Should return array
        $results | Should -Not -BeNullOrEmpty
        $results | Should -BeOfType System.Array

        # Products should have required fields from Product schema
        if ($results.Count -gt 0)
        {
            $firstProduct = $results[0]
            $firstProduct.PSObject.Properties.Name | Should -Contain 'productId'
            $firstProduct.PSObject.Properties.Name | Should -Contain 'upc'
            $firstProduct.PSObject.Properties.Name | Should -Contain 'description'
        }
    }

    It 'Search-KrogerProduct supports UPC parameter per swagger definition' {
        $results = Search-KrogerProduct -Upc '0001111007790'

        # Should return products with matching UPC
        $results | Should -Not -BeNullOrEmpty
        foreach ($product in $results)
        {
            $product.upc | Should -Be '0001111007790'
        }
    }

    It 'Add-KrogerCartItem requires user authentication' {
        # Test that cart operations require proper authentication
        $anonToken = Connect-KrogerApi -Scope @('cart.basic')

        # Clear any existing user session to test anonymous cart
        Disconnect-KrogerUser -ErrorAction SilentlyContinue

        # Should fail without user authentication
        { '0001111007790' | Add-KrogerCartItem -Quantity 1 -ErrorAction Stop } |
            Should -Throw -ErrorId '*'
    }
}

Describe 'Kroger API Error Handling' -Skip:(-not $hasApiCredentials -or $isCI) {
    It 'Invalid OAuth2 credentials return proper error format' {
        $body = @{
            grant_type    = 'client_credentials'
            client_id     = 'invalid_client_id'
            client_secret = 'invalid_secret'
        }

        try
        {
            $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/connect/oauth2/token' `
                -Method Post `
                -Body $body `
                -ErrorAction Stop
        } catch
        {
            # Error response should match Error schema
            if ($_.ErrorDetails)
            {
                $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
                $errorResponse.PSObject.Properties.Name | Should -Contain 'error'
                $errorResponse.PSObject.Properties.Name | Should -Contain 'error_description'
            }
        }
    }

    It 'Invalid product search returns empty results' {
        $token = Connect-KrogerApi -Scope @('product.compact')

        $headers = @{
            Authorization = "Bearer $($token.access_token)"
            'Accept'      = 'application/json'
        }

        $params = @{
            'filter.term' = 'xyznonexistentproduct123'
            pageSize      = 10
        }

        $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/products' `
            -Method Get `
            -Headers $headers `
            -Body $params `
            -ErrorAction Stop

        # Should return empty array for no results
        $response.data | Should -BeNullOrEmpty -or $response.data.Count | Should -Be 0
    }
}

AfterAll {
    Write-Host "=== Kroger API Swagger-Based Test Summary ===" -ForegroundColor Cyan
    Write-Host "Swagger Documentation: $swaggerPath" -ForegroundColor White
    Write-Host "Has API Credentials: $hasApiCredentials" -ForegroundColor $(if ($hasApiCredentials) { 'Green' } else { 'Yellow' })
    Write-Host "Running in CI: $isCI" -ForegroundColor $(if ($isCI) { 'Yellow' } else { 'Green' })
    Write-Host ""

    if ($isCI)
    {
        Write-Host "Note: Real API tests were skipped in CI environment" -ForegroundColor Yellow
    } elseif (-not $hasApiCredentials)
    {
        Write-Host "Note: Real API tests were skipped due to missing credentials" -ForegroundColor Yellow
        Write-Host "Set KrogerClientId and KrogerApiKey secrets to enable real API testing" -ForegroundColor Yellow
    }
}
