function Connect-KrogerUser
{
    <#
    .SYNOPSIS
    Authenticates a user with Kroger API for personal cart access.

    .DESCRIPTION
    Provides multiple methods for user authentication:
    1. Automatic (loads saved credentials from secrets)
    2. Direct login with username/password
    3. Manual token entry

    .PARAMETER UseSavedCredentials
    Automatically load credentials from saved secrets.

    .PARAMETER Username
    Kroger account email/username (for password grant).

    .PARAMETER Password
    Kroger account password (for password grant).

    .PARAMETER AccessToken
    Manually provide an OAuth2 access token.

    .PARAMETER RefreshToken
    Optionally provide a refresh token for automatic token renewal.

    .PARAMETER ForceReauth
    Force re-authentication even if existing session exists.

    .PARAMETER ClientId
    OAuth2 client ID. Defaults to retrieving from secret store.

    .PARAMETER ClientSecret
    OAuth2 client secret. Defaults to retrieving from secret store.

    .PARAMETER SavedUsername
    Saved username from secret store (for testing).

    .PARAMETER SavedPassword
    Saved password from secret store (for testing).

    .EXAMPLE
    Connect-KrogerUser -UseSavedCredentials

    .EXAMPLE
    Connect-KrogerUser -Username 'user@example.com' -Password 'password123'

    .EXAMPLE
    Connect-KrogerUser -AccessToken 'your_access_token'

    .EXAMPLE
    Connect-KrogerUser -ClientId 'test_client' -ClientSecret 'test_secret' -Username 'user@test.com' -Password 'pass123'

    .OUTPUTS
    PSObject with user authentication token and profile information.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Auto')]
    param(
        [Parameter(ParameterSetName = 'Auto')]
        [switch]$UseSavedCredentials,

        [Parameter(ParameterSetName = 'Manual')]
        [string]$Username,

        [Parameter(ParameterSetName = 'Manual')]
        [string]$Password,

        [Parameter(ParameterSetName = 'Token')]
        [string]$AccessToken,

        [Parameter(ParameterSetName = 'Token')]
        [string]$RefreshToken,

        [Parameter()]
        [switch]$ForceReauth,

        [Parameter()]
        [string]$ClientId = (Get-Secret -Name 'KrogerClientId' -AsPlainText -ErrorAction SilentlyContinue),

        [Parameter()]
        [string]$ClientSecret = (Get-Secret -Name 'KrogerApiKey' -AsPlainText -ErrorAction SilentlyContinue),

        [Parameter()]
        [string]$SavedUsername = (Get-Secret -Name 'KrogerUsername' -AsPlainText -ErrorAction SilentlyContinue),

        [Parameter()]
        [string]$SavedPassword = (Get-Secret -Name 'KrogerPassword' -AsPlainText -ErrorAction SilentlyContinue)
    )

    begin
    {
        Write-Verbose "Starting Kroger user authentication"

        # Check for existing session (only for default case)
        if ($PSCmdlet.ParameterSetName -eq 'Auto' -and -not $ForceReauth -and -not $UseSavedCredentials)
        {
            $existingSession = Get-KrogerUserSession
            if ($existingSession -and -not (Test-WebApiTokenExpired -Token $existingSession.token))
            {
                Write-Verbose "Using existing user session"
                Write-Host "✓ Already signed in as $($existingSession.profile.name)" -ForegroundColor Green
                return $existingSession
            }
        }

        # Validate we have API credentials
        if (-not $ClientId -or -not $ClientSecret)
        {
            throw "Kroger API credentials not found. Please set them using Set-Secret."
        }
    }

    process
    {
        if ($UseSavedCredentials -or ($PSCmdlet.ParameterSetName -eq 'Auto' -and -not $ForceReauth))
        {
            # Load credentials from parameters (which default to secrets)
            if ($SavedUsername -and $SavedPassword)
            {
                Write-Host "Loading saved credentials for: $SavedUsername" -ForegroundColor Cyan
                return Invoke-KrogerPasswordGrant -Username $SavedUsername -Password $SavedPassword -ClientId $ClientId -ClientSecret $ClientSecret
            } else
            {
                Write-Host "✗ No saved credentials found" -ForegroundColor Red
                Write-Host ""
                Write-Host "Troubleshooting:" -ForegroundColor Yellow
                Write-Host "1. Set saved credentials: Set-Secret -Name 'KrogerUsername' -Secret 'your-email'" -ForegroundColor White
                Write-Host "2. Set saved password: Set-Secret -Name 'KrogerPassword' -Secret 'your-password'" -ForegroundColor White
                Write-Host "2. Your OAuth2 app may not support password grant" -ForegroundColor White
                Write-Host "3. Try: Connect-KrogerUser -AccessToken 'manual_token'" -ForegroundColor White
                Write-Host ""
                throw "Authentication failed: $_"
            }
        } elseif ($Username -and $Password)
        {
            # Password grant type (direct login)
            return Invoke-KrogerPasswordGrant -Username $Username -Password $Password -ClientId $clientId -ClientSecret $clientSecret
        } elseif ($AccessToken)
        {
            # Manual token entry
            return Set-KrogerUserToken -AccessToken $AccessToken -RefreshToken $RefreshToken
        } else
        {
            # Show authentication instructions
            Show-KrogerAuthInstructions
        }
    }

    end
    {
        Write-Verbose "Kroger user authentication completed"
    }
}

function Disconnect-KrogerUser
{
    <#
    .SYNOPSIS
    Signs out the current Kroger user and clears session.

    .DESCRIPTION
    Removes the stored user session and authentication tokens.

    .EXAMPLE
    Disconnect-KrogerUser

    .OUTPUTS
    Boolean indicating success.
    #>
    [CmdletBinding()]
    param()

    begin
    {
        Write-Verbose "Signing out Kroger user"
    }

    process
    {
        try
        {
            # Clear user session from file
            $sessionPath = Get-KrogerSessionPath
            if (Test-Path $sessionPath)
            {
                Remove-Item $sessionPath -Force
                Write-Verbose "User session file deleted"
            }

            # Clear in-memory cache
            $Script:KrogerUserSession = $null

            return $true
        } catch
        {
            Write-Error "Failed to sign out: $_"
            return $false
        }
    }

    end
    {
        Write-Verbose "User sign-out completed"
    }
}

function Get-KrogerUserSession
{
    <#
    .SYNOPSIS
    Retrieves the current Kroger user session.

    .DESCRIPTION
    Gets the stored user session information including authentication tokens and user profile.

    .EXAMPLE
    Get-KrogerUserSession

    .OUTPUTS
    PSObject with user session data or null if not authenticated.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param()

    begin
    {
        # Check in-memory cache first
        if ($null -ne $Script:KrogerUserSession)
        {
            return $Script:KrogerUserSession
        }
    }

    process
    {
        try
        {
            # Try to get session from file
            $sessionPath = Get-KrogerSessionPath
            if (Test-Path $sessionPath)
            {
                $sessionData = Import-Clixml -Path $sessionPath

                # Check if token is expired
                if (Test-WebApiTokenExpired -Token $sessionData.token)
                {
                    Write-Verbose "User session token expired, attempting refresh..."
                    if (Update-KrogerUserToken)
                    {
                        # Reload session after refresh
                        $sessionData = Import-Clixml -Path $sessionPath
                    } else
                    {
                        Write-Warning "Kroger authentication expired. Please re-run: Connect-KrogerPkce"
                        Remove-Item $sessionPath -Force -ErrorAction SilentlyContinue
                        return $null
                    }
                }

                # Cache in memory
                $Script:KrogerUserSession = $sessionData
                return $sessionData
            } else
            {
                Write-Verbose "No user session found"
                return $null
            }
        } catch
        {
            Write-Error "Failed to retrieve user session: $_"
            return $null
        }
    }
}

function Update-KrogerUserToken
{
    <#
    .SYNOPSIS
    Refreshes the expired user token using the refresh token.

    .DESCRIPTION
    Uses the refresh token from the user session to obtain a new access token.

    .EXAMPLE
    Update-KrogerUserToken

    .OUTPUTS
    Boolean indicating success.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    begin
    {
        # Try to get session from file
        $sessionPath = Get-KrogerSessionPath
        if (-not (Test-Path $sessionPath))
        {
            Write-Warning "No session file found"
            return $false
        }

        $sessionData = Import-Clixml -Path $sessionPath

        if (-not $sessionData.token.refresh_token)
        {
            Write-Warning "No refresh token available"
            return $false
        }
    }

    process
    {
        try
        {
            Write-Verbose "Refreshing user token..."

            # Use client_id from session if available
            $clientId = if ($sessionData.clientId)
            {
                $sessionData.clientId
            } else
            {
                Write-Verbose "No client_id in session, may need to re-authenticate"
            }

            # Build refresh request (PKCE public client - no client_secret needed)
            $body = @{
                grant_type    = 'refresh_token'
                refresh_token = $sessionData.token.refresh_token
            }

            if ($clientId)
            {
                $body['client_id'] = $clientId
            }

            # Request new token
            $response = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/connect/oauth2/token' -Method Post -Body $body -ErrorAction Stop

            # Add expiration timestamp
            $response | Add-Member -NotePropertyName 'expires_at' -NotePropertyValue (Get-Date).AddSeconds($response.expires_in) -Force

            # Update session (preserve client_id and other fields)
            $previousClientId = $sessionData.clientId
            $previousProfile = $sessionData.profile
            $previousAuthTime = $sessionData.authenticatedAt

            $sessionData.token = $response
            $sessionData.clientId = $previousClientId
            $sessionData.profile = $previousProfile
            $sessionData.authenticatedAt = $previousAuthTime

            Save-KrogerUserSession -Session $sessionData

            Write-Verbose "Token refreshed successfully"
            return $true
        } catch
        {
            Write-Verbose "Token refresh failed: $_"
            # Remove expired session file
            $sessionPath = Get-KrogerSessionPath
            if (Test-Path $sessionPath)
            {
                Remove-Item $sessionPath -Force
            }
            return $false
        }
    }
}

function Get-KrogerCartId
{
    <#
    .SYNOPSIS
    Gets the cart ID for the authenticated user.

    .DESCRIPTION
    Retrieves the cart ID associated with the current user session.
    If no cart exists, creates a new one.

    .EXAMPLE
    Get-KrogerCartId

    .OUTPUTS
    String containing the cart ID.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    begin
    {
        $session = Get-KrogerUserSession
        if (-not $session)
        {
            throw "Not authenticated. Please run Connect-KrogerUser first."
        }

        $token = $session.token
    }

    process
    {
        try
        {
            # Try to get existing cart
            $headers = @{
                Authorization = "Bearer $($token.access_token)"
                'Accept'      = 'application/json'
            }

            $response = Invoke-WebApi -Method GET -Uri 'https://api.kroger.com/v1/cart' -Headers $headers

            if ($response -and $response.id)
            {
                Write-Verbose "Found existing cart: $($response.id)"
                return $response.id
            } else
            {
                # Create new cart
                Write-Verbose "Creating new cart"
                $newCart = Invoke-WebApi -Method POST -Uri 'https://api.kroger.com/v1/cart' -Headers $headers

                if ($newCart -and $newCart.id)
                {
                    # Save cart ID to session
                    $session.cartId = $newCart.id
                    Save-KrogerUserSession -Session $session

                    return $newCart.id
                } else
                {
                    throw "Failed to create cart"
                }
            }
        } catch
        {
            throw "Failed to get cart ID: $_"
        }
    }
}

# Helper functions

function Invoke-KrogerPasswordGrant
{
    <#
    .SYNOPSIS
    Performs OAuth2 password grant for direct user authentication.

    .DESCRIPTION
    Uses the Resource Owner Password Credentials grant type to authenticate
    a user directly with their Kroger username and password.

    .PARAMETER Username
    User's Kroger account email/username.

    .PARAMETER Password
    User's Kroger account password.

    .PARAMETER ClientId
    OAuth2 client ID.

    .PARAMETER ClientSecret
    OAuth2 client secret.

    .OUTPUTS
    PSObject with user authentication session.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Password,

        [Parameter(Mandatory)]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [string]$ClientSecret
    )

    try
    {
        Write-Host "=== Kroger User Authentication ===" -ForegroundColor Green
        Write-Host ""
        Write-Verbose "Attempting password grant authentication"

        # Try without scopes first (let server decide defaults)
        $body = @{
            grant_type    = 'password'
            username      = $Username
            password      = $Password
            client_id     = $ClientId
            client_secret = $ClientSecret
        }

        Write-Host "Authenticating as: $Username" -ForegroundColor Cyan
        Write-Host ""

        # Try password grant
        $tokenResponse = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/connect/oauth2/token' -Method Post -Body $body -ErrorAction Stop

        # Process token
        $token = $tokenResponse | Add-Member -NotePropertyName 'expires_at' -NotePropertyValue (Get-Date).AddSeconds($tokenResponse.expires_in) -Force -PassThru

        # Get user profile
        $profile = Get-KrogerUserProfile -Token $token

        # Create session
        $session = @{
            token           = $token
            profile         = $profile
            authenticatedAt = Get-Date
            clientId        = $ClientId
        }

        # Save session
        Save-KrogerUserSession -Session $session

        Write-Host "✓ Authentication successful!" -ForegroundColor Green
        Write-Host "  Signed in as: $($profile.name)" -ForegroundColor Cyan
        Write-Host ""

        return $session
    } catch
    {
        $errorDetails = if ($_.ErrorDetails)
        {
            try
            {
                $_.ErrorDetails.Message | ConvertFrom-Json
            } catch
            {
                @{ error = 'unknown'; error_description = $_.Exception.Message }
            }
        } else
        {
            @{ error = 'unknown'; error_description = $_.Exception.Message }
        }

        if ($errorDetails.error -eq 'unsupported_grant_type')
        {
            Write-Host "✗ Password grant not supported by your Kroger OAuth2 app" -ForegroundColor Red
            Write-Host ""
            Write-Host "What you can still do:" -ForegroundColor Yellow
            Write-Host "✓ Product search: Search-KrogerProduct -SearchTerm 'milk'" -ForegroundColor Green
            Write-Host "✓ Product filtering and sorting" -ForegroundColor Green
            Write-Host ""
            Write-Host "For cart access, you'll need to:" -ForegroundColor Yellow
            Write-Host "1. Use Kroger's OAuth2 playground to get a token" -ForegroundColor White
            Write-Host "2. Or check if your OAuth2 app supports authorization code flow" -ForegroundColor White
            Write-Host ""
        } elseif ($errorDetails.error -eq 'invalid_scope')
        {
            Write-Host "✗ Your OAuth2 app doesn't have permission for user authentication" -ForegroundColor Red
            Write-Host ""
            Write-Host "What you can still do:" -ForegroundColor Yellow
            Write-Host "✓ Product search: Search-KrogerProduct -SearchTerm 'milk'" -ForegroundColor Green
            Write-Host "✓ Product filtering by brand, category, price" -ForegroundColor Green
            Write-Host ""
            Write-Host "The Kroger API limits what OAuth2 apps can access." -ForegroundColor Yellow
            Write-Host "Most apps only support product search, not personal cart access." -ForegroundColor Yellow
            Write-Host ""
        } elseif ($errorDetails.error -eq 'invalid_grant')
        {
            Write-Host "✗ Invalid username or password" -ForegroundColor Red
            Write-Host ""
            Write-Host "Please check:" -ForegroundColor Yellow
            Write-Host "• Your Kroger email and password are correct" -ForegroundColor White
            Write-Host "• You're using the same credentials as kroger.com" -ForegroundColor White
            Write-Host ""
        } else
        {
            Write-Host "✗ Authentication failed: $($errorDetails.error_description)" -ForegroundColor Red
            Write-Host ""
        }

        throw "Password grant authentication failed: $($errorDetails.error_description)"
    }
}

function Set-KrogerUserToken
{
    <#
    .SYNOPSIS
    Sets the user authentication token manually.

    .DESCRIPTION
    Stores a manually provided OAuth2 access token for user authentication.

    .PARAMETER AccessToken
    OAuth2 access token.

    .PARAMETER RefreshToken
    Optional OAuth2 refresh token.

    .OUTPUTS
    PSObject with user authentication session.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter()]
        [string]$RefreshToken
    )

    try
    {
        Write-Verbose "Setting user authentication token"

        # Create token object
        $token = @{
            access_token  = $AccessToken
            token_type    = 'Bearer'
            expires_in    = 3600
            expires_at    = (Get-Date).AddHours(1)
            refresh_token = $RefreshToken
        }

        # Try to get user profile
        $profile = Get-KrogerUserProfile -Token $token

        # Create session
        $session = @{
            token           = $token
            profile         = $profile
            authenticatedAt = Get-Date
            clientId        = $ClientId
        }

        # Save session
        Save-KrogerUserSession -Session $session

        Write-Host "✓ Authentication successful!" -ForegroundColor Green
        Write-Host "  Signed in as: $($profile.name)" -ForegroundColor Cyan
        Write-Host ""

        return $session
    } catch
    {
        throw "Failed to set user token: $_"
    }
}

function Show-KrogerAuthInstructions
{
    <#
    .SYNOPSIS
    Displays instructions for manual OAuth2 authentication.

    .DESCRIPTION
    Shows step-by-step instructions for obtaining OAuth2 tokens
    and using them with Connect-KrogerUser.
    #>
    [CmdletBinding()]
    param()

    process
    {
        Write-Host "=== Kroger User Authentication ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "To access your personal Kroger cart, you need to authenticate." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1: Use OAuth2 Tokens (Recommended)" -ForegroundColor Cyan
        Write-Host "  1. Go to: https://developer.kroger.com" -ForegroundColor White
        Write-Host "  2. Create an account and get your API credentials" -ForegroundColor White
        Write-Host "  3. Use their OAuth2 playground or tools to get access tokens" -ForegroundColor White
        Write-Host "  4. Run: Connect-KrogerUser -AccessToken 'your_token_here'" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2: Use Product Search Only (No Cart Access)" -ForegroundColor Cyan
        Write-Host "  1. Just use API credentials for product search:" -ForegroundColor White
        Write-Host "  2. Search-KrogerProduct -SearchTerm 'milk'" -ForegroundColor White
        Write-Host "  3. Note: This won't access your personal cart" -ForegroundColor White
        Write-Host ""
        Write-Host "For more information, see: Get-Help Connect-KrogerUser -Examples" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Get-KrogerUserProfile
{
    <#
    .SYNOPSIS
    Gets the user profile information using the access token.

    .DESCRIPTION
    Retrieves the authenticated user's profile information from Kroger API.

    .PARAMETER Token
    OAuth2 access token.

    .OUTPUTS
    PSObject with user profile data.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Token
    )

    try
    {
        $headers = @{
            Authorization = "Bearer $($Token.access_token)"
            'Accept'      = 'application/json'
        }

        $response = Invoke-WebRequest -Uri 'https://api.kroger.com/v1/profile' -Method Get -Headers $headers -ErrorAction Stop

        if ($response.StatusCode -eq 200)
        {
            $profileData = $response.Content | ConvertFrom-Json
            return @{
                id    = $profileData.id
                name  = $profileData.name
                email = $profileData.email
            }
        } else
        {
            # Profile endpoint not available, return default
            return @{
                id    = $null
                name  = 'Kroger User'
                email = $null
            }
        }
    } catch
    {
        # Profile endpoint not available or unauthorized - return default profile silently
        # This is not critical for cart functionality
        Write-Verbose "Profile API not available, using default profile"
        return @{
            id    = $null
            name  = 'Kroger User'
            email = $null
        }
    }
}

function Save-KrogerUserSession
{
    <#
    .SYNOPSIS
    Saves the user session to a secure file (avoiding SecretStore JSON issues).

    .DESCRIPTION
    Persists the user session including tokens and profile to a secure file.
    Uses file-based storage to avoid SecretStore serialization issues with complex objects.

    .PARAMETER Session
    Session object to save.

    .OUTPUTS
    Boolean indicating success.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Session
    )

    try
    {
        # Use file-based storage to avoid SecretStore serialization issues
        $sessionPath = Get-KrogerSessionPath
        $sessionDir = Split-Path $sessionPath

        if (-not (Test-Path $sessionDir))
        {
            New-Item -Path $sessionDir -ItemType Directory -Force | Out-Null
        }

        # Save as CLIXML to preserve object types
        Export-Clixml -InputObject $Session -Path $sessionPath -Force

        # Update in-memory cache
        $Script:KrogerUserSession = $session

        Write-Verbose "User session saved to file"
        return $true
    } catch
    {
        Write-Error "Failed to save user session: $_"
        return $false
    }
}

function Get-KrogerSessionPath
{
    <#
    .SYNOPSIS
    Gets the path to the user session file.

    .DESCRIPTION
    Returns the platform-specific path for storing the user session.

    .OUTPUTS
    String containing the session file path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    # Use XDG cache directory on Linux/Mac, LocalAppData on Windows
    if ($IsWindows)
    {
        $cacheDir = Join-Path $env:LOCALAPPDATA 'DotWebApi'
    } else
    {
        # XDG cache directory
        $cacheDir = if ($env:XDG_CACHE_HOME)
        {
            Join-Path $env:XDG_CACHE_HOME 'dotwebapi'
        } else
        {
            Join-Path $HOME '.cache' 'dotwebapi'
        }
    }

    return Join-Path $cacheDir 'kroger_session.json'
}

# Initialize script-level variables
$Script:KrogerUserSession = $null
