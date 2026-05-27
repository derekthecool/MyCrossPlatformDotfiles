BeforeAll {
    Import-Module $PSScriptRoot/../../DotWebApi.psd1 -Force

    # Mock valid token response
    $MockValidToken = @{
        access_token  = 'test_token_12345'
        token_type    = 'Bearer'
        expires_in    = 3600
        expires_at    = (Get-Date).AddHours(1)
        scope         = 'test.scope'
    }

    # Mock expired token response
    $MockExpiredToken = @{
        access_token  = 'expired_token_12345'
        token_type    = 'Bearer'
        expires_in    = 3600
        expires_at    = (Get-Date).AddHours(-2) # Expired 2 hours ago
        scope         = 'test.scope'
    }

    # Mock token about to expire (within buffer time)
    $MockExpiringToken = @{
        access_token  = 'expiring_token_12345'
        token_type    = 'Bearer'
        expires_in    = 3600
        expires_at    = (Get-Date).AddMinutes(2) # Expires in 2 minutes
        scope         = 'test.scope'
    }

    # Mock API override for token requests
    $Script:MockWebApiOverride = {
        param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

        # Mock token endpoint
        if ($Uri -match 'oauth2/token') {
            return $MockValidToken
        }

        throw "Mock API endpoint not implemented: $Uri"
    }
}

AfterAll {
    # Clear mock override
    $Script:MockWebApiOverride = $null
    # Clear token cache
    Clear-WebApiTokenCache
}

Describe 'Get-WebApiToken' {
    BeforeEach {
        # Clear token cache before each test
        Clear-WebApiTokenCache
    }

    It 'Obtains new OAuth2 token from token endpoint' {
        $token = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('product.compact')

        $token | Should -Not -BeNullOrEmpty
        $token.access_token | Should -Be 'test_token_12345'
        $token.token_type | Should -Be 'Bearer'
    }

    It 'Caches token for subsequent calls' {
        $token1 = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('product.compact')
        $token2 = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('product.compact')

        $token1.access_token | Should -Be $token2.access_token
    }

    It 'Adds expiration timestamp to token response' {
        $token = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('product.compact')

        $token.expires_at | Should -Not -BeNullOrEmpty
        $token.expires_at | Should -BeOfType [datetime]
    }

    It 'Forces token refresh when ForceRefresh is specified' {
        # Make first call to cache token
        $token1 = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('product.compact')

        # Mock new token for second call
        $newToken = @{
            access_token  = 'new_token_67890'
            token_type    = 'Bearer'
            expires_in    = 3600
            expires_at    = (Get-Date).AddHours(1)
            scope         = 'test.scope'
        }

        $refreshMock = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $newToken
            }

            throw "Mock API endpoint not implemented: $Uri"
        }

        $Script:MockWebApiOverride = $refreshMock

        # Force refresh should get new token
        $token2 = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('product.compact') -ForceRefresh

        $token2.access_token | Should -Be 'new_token_67890'
        $token2.access_token | Should -Not -Be $token1.access_token

        # Restore original mock
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockValidToken
            }

            throw "Mock API endpoint not implemented: $Uri"
        }
    }

    It 'Handles multiple services independently' {
        # Mock different tokens for different services
        $krogerMock = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'kroger') {
                return @{
                    access_token = 'kroger_token'
                    expires_in   = 3600
                    expires_at   = (Get-Date).AddHours(1)
                }
            }

            throw "Mock API endpoint not implemented: $Uri"
        }

        $Script:MockWebApiOverride = $krogerMock

        $krogerToken = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('product.compact')

        $krogerToken.access_token | Should -Be 'kroger_token'

        # Restore original mock
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockValidToken
            }

            throw "Mock API endpoint not implemented: $Uri"
        }
    }

    It 'Joins multiple scopes correctly' {
        $token = Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope @('cart.basic', 'cart.write')

        $token.scope | Should -Match 'cart\.basic'
        $token.scope | Should -Match 'cart\.write'
    }
}

Describe 'Test-WebApiTokenExpired' {
    It 'Returns false for valid token' {
        $result = Test-WebApiTokenExpired -Token $MockValidToken
        $result | Should -Be $false
    }

    It 'Returns true for expired token' {
        $result = Test-WebApiTokenExpired -Token $MockExpiredToken
        $result | Should -Be $true
    }

    It 'Returns true for token expiring within buffer time' {
        $result = Test-WebApiTokenExpired -Token $MockExpiringToken -BufferMinutes 5
        $result | Should -Be $true
    }

    It 'Returns true for token without expiration timestamp' {
        $invalidToken = @{
            access_token = 'test_token'
            token_type   = 'Bearer'
            # Missing expires_at
        }

        $result = Test-WebApiTokenExpired -Token $invalidToken
        $result | Should -Be $true
    }

    It 'Returns true for null token' {
        $result = Test-WebApiTokenExpired -Token $null
        $result | Should -Be $true
    }

    It 'Respects custom buffer time' {
        # Token that expires in 10 minutes
        $token = @{
            access_token = 'test_token'
            expires_at   = (Get-Date).AddMinutes(10)
        }

        # With 5 minute buffer, should not be expired
        $result1 = Test-WebApiTokenExpired -Token $token -BufferMinutes 5
        $result1 | Should -Be $false

        # With 15 minute buffer, should be expired
        $result2 = Test-WebApiTokenExpired -Token $token -BufferMinutes 15
        $result2 | Should -Be $true
    }
}

Describe 'Clear-WebApiTokenCache' {
    BeforeEach {
        # Clear cache and populate with test data
        Clear-WebApiTokenCache

        # Add some cached tokens
        $Script:WebApiTokenCache['Kroger'] = $MockValidToken
        $Script:WebApiTokenCache['TestService'] = $MockExpiredToken
    }

    It 'Clears all cached tokens when no service specified' {
        $Script:WebApiTokenCache.Count | Should -BeGreaterOrEqual 2

        Clear-WebApiTokenCache

        $Script:WebApiTokenCache.Count | Should -Be 0
    }

    It 'Clears specific service token' {
        $Script:WebApiTokenCache.ContainsKey('Kroger') | Should -Be $true

        Clear-WebApiTokenCache -ServiceName 'Kroger'

        $Script:WebApiTokenCache.ContainsKey('Kroger') | Should -Be $false
        $Script:WebApiTokenCache.ContainsKey('TestService') | Should -Be $true
    }

    It 'Handles non-existent service gracefully' {
        # Should not throw error
        { Clear-WebApiTokenCache -ServiceName 'NonExistent' } | Should -Not -Throw
    }
}

Describe 'Token Cache Integration' {
    BeforeEach {
        Clear-WebApiTokenCache
    }

    It 'Uses cached token when valid' {
        # Setup mock to return different tokens on first vs second call
        $callCount = 0
        $tokenMocks = @(
            @{ access_token = 'first_token'; expires_in = 3600; expires_at = (Get-Date).AddHours(1) },
            @{ access_token = 'second_token'; expires_in = 3600; expires_at = (Get-Date).AddHours(1) }
        )

        $sequentialMock = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                $script:callCount++
                return $tokenMocks[$script:callCount - 1]
            }

            throw "Mock API endpoint not implemented: $Uri"
        }.GetNewClosure()

        $Script:MockWebApiOverride = $sequentialMock

        # First call gets 'first_token'
        $token1 = Get-WebApiToken -ServiceName 'Test' -TokenEndpoint 'https://api.test.com/token' -Scope @('test')
        $token1.access_token | Should -Be 'first_token'

        # Second call should use cached 'first_token', not get 'second_token'
        $token2 = Get-WebApiToken -ServiceName 'Test' -TokenEndpoint 'https://api.test.com/token' -Scope @('test')
        $token2.access_token | Should -Be 'first_token'

        # Verify only one API call was made
        $callCount | Should -Be 1

        # Restore original mock
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockValidToken
            }

            throw "Mock API endpoint not implemented: $Uri"
        }
    }

    It 'Refreshes expired token automatically' {
        # Setup mock with expiring token
        $expiringToken = @{
            access_token = 'expiring_token'
            expires_in   = 60
            expires_at   = (Get-Date).AddSeconds(-10) # Already expired
        }

        $refreshedToken = @{
            access_token = 'refreshed_token'
            expires_in   = 3600
            expires_at   = (Get-Date).AddHours(1)
        }

        # Cache expired token
        $Script:WebApiTokenCache['Test'] = $expiringToken

        # Setup mock to return refreshed token
        $refreshMock = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $refreshedToken
            }

            throw "Mock API endpoint not implemented: $Uri"
        }

        $Script:MockWebApiOverride = $refreshMock

        # Should automatically get refreshed token
        $token = Get-WebApiToken -ServiceName 'Test' -TokenEndpoint 'https://api.test.com/token' -Scope @('test')
        $token.access_token | Should -Be 'refreshed_token'

        # Restore original mock
        $Script:MockWebApiOverride = {
            param($Method, $Uri, $Body, $ContentType, $TimeoutSec)

            if ($Uri -match 'oauth2/token') {
                return $MockValidToken
            }

            throw "Mock API endpoint not implemented: $Uri"
        }
    }
}
