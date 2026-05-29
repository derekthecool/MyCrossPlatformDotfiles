function Connect-KrogerPkce {
    <#
    .SYNOPSIS
    Authenticates using PKCE authorization code flow (recommended method).

    .DESCRIPTION
    Implements the PKCE (Proof Key for Code Exchange) authorization code flow
    which is the OAuth2 best practice for CLI applications. This matches the
    successful implementation used by the CupOfOwls/kroger-api project.

    .PARAMETER ClientId
    OAuth2 client ID from Kroger Developer Portal.

    .PARAMETER ClientSecret
    OAuth2 client secret from Kroger Developer Portal.

    .PARAMETER RedirectUri
    Redirect URI (must match what's registered in Kroger Developer Portal).

    .EXAMPLE
    Connect-KrogerPkce

    .OUTPUTS
    PSObject with authentication session.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$RedirectUri = 'http://localhost:8080/callback',

        [Parameter()]
        [int]$Timeout = 300,

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$ClientSecret
    )

    begin {
        Write-Verbose "Starting PKCE authentication"

        # Get API credentials if not provided
        if (-not $ClientId) {
            try {
                $ClientId = Get-Secret -Name 'KrogerClientId' -AsPlainText -ErrorAction Stop
            }
            catch {
                throw "Kroger ClientId not found. Please set it using Set-Secret."
            }
        }

        if (-not $ClientSecret) {
            try {
                $ClientSecret = Get-Secret -Name 'KrogerApiKey' -AsPlainText -ErrorAction Stop
            }
            catch {
                throw "Kroger ApiKey (ClientSecret) not found. Please set it using Set-Secret."
            }
        }
    }

    process {
        try {
            Write-Host "=== Kroger PKCE Authentication ===" -ForegroundColor Green
            Write-Host ""

            # Generate PKCE parameters
            $codeVerifier = [Guid]::NewGuid().ToString() + [Guid]::NewGuid().ToString()

            # Simple code challenge (URL-safe base64)
            $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($codeVerifier))
            $codeChallengeBase64 = [System.Convert]::ToBase64String($hash)
            $codeChallenge = $codeChallengeBase64.Replace('+', '-').Replace('/', '_').Replace('=', '')

            # Generate state parameter
            $state = [Guid]::NewGuid().ToString()

            # Build authorization URL with CORRECT scope format
            $scopes = "cart.basic:write profile.compact"
            $authUrl = "https://api.kroger.com/v1/connect/oauth2/authorize?" +
                "client_id=$ClientId&" +
                "redirect_uri=$([System.Web.HttpUtility]::UrlEncode($RedirectUri))&" +
                "response_type=code&" +
                "scope=$([System.Web.HttpUtility]::UrlEncode($scopes))&" +
                "state=$state&" +
                "code_challenge=$codeChallenge&" +
                "code_challenge_method=S256"

            Write-Host "Opening browser for authentication..." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "1. Your browser will open to Kroger's authorization page" -ForegroundColor Yellow
            Write-Host "2. Sign in with your Kroger credentials" -ForegroundColor Yellow
            Write-Host "3. Authorize the application" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Waiting for authorization callback..." -ForegroundColor Green

            # Start HTTP listener for callback
            Write-Verbose "Starting HTTP listener on port 8080"
            $listener = [System.Net.HttpListener]::new()
            $listener.Prefixes.Add('http://localhost:8080/')

            try {
                $listener.Start()

                # Open browser
                Start-Process $authUrl

                # Wait for callback (with timeout)
                $context = $listener.GetContext()
                $request = $context.Request
                $response = $context.Response

                # Parse query parameters
                $query = $request.Url.Query
                $params = [System.Web.HttpUtility]::ParseQueryString($query)

                if ($params['error']) {
                    $error = $params['error']
                    $errorDesc = if ($params['error_description']) { $params['error_description'] } else { $error }

                    # Send error response
                    $html = "<html><body><h1>Authentication Failed</h1><p>$errorDesc</p></body></html>"
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $response.Close()

                    throw "Authentication failed: $errorDesc"
                }

                if ($params['code']) {
                    $authCode = $params['code']
                    $returnedState = $params['state']

                    # Verify state
                    if ($returnedState -ne $state) {
                        throw "State mismatch - possible CSRF attack"
                    }

                    Write-Verbose "Authorization code received, exchanging for token..."

                    # Exchange authorization code for token
                    $body = @{
                        grant_type    = 'authorization_code'
                        code          = $authCode
                        redirect_uri  = $RedirectUri
                        client_id     = $ClientId
                        code_verifier = $codeVerifier
                    }

                    $tokenResponse = Invoke-RestMethod -Uri 'https://api.kroger.com/v1/connect/oauth2/token' -Method Post -Body $body

                    # Send success response
                    $html = "<html><body><h1>Authentication Successful!</h1><p>You can close this window and return to PowerShell.</p></body></html>"
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $response.Close()

                    Write-Host "✓ Authentication successful!" -ForegroundColor Green

                    # Process token
                    $token = $tokenResponse | Add-Member -NotePropertyName 'expires_at' -NotePropertyValue (Get-Date).AddSeconds($tokenResponse.expires_in) -Force -PassThru

                    # Get user profile
                    $profile = Get-KrogerUserProfile -Token $token

                    # Create session
                    $session = @{
                        token  = $token
                        profile = $profile
                        authenticatedAt = Get-Date
                        clientId = $ClientId  # Store for token refresh
                    }

                    # Save session
                    Save-KrogerUserSession -Session $session

                    Write-Host "  Signed in as: $($profile.name)" -ForegroundColor Cyan
                    Write-Host "  Scope: $scopes" -ForegroundColor Cyan
                    Write-Host ""

                    return $session
                }
                else {
                    throw "No authorization code received"
                }
            }
            finally {
                $listener.Stop()
                $listener.Close()
            }

            Write-Verbose "PKCE authentication completed"
        }
        catch {
            Write-Host "✗ PKCE authentication failed: $_" -ForegroundColor Red
            throw
        }
    }
}

function Get-KrogerCorrectScopes {
    <#
    .SYNOPSIS
    Returns the correct OAuth2 scope format for Kroger API.

    .DESCRIPTION
    Based on the CupOfOwls/kroger-api implementation, returns the properly
    formatted scope string for Kroger OAuth2 authentication.

    .EXAMPLE
    Get-KrogerCorrectScopes

    .OUTPUTS
    String with correct scope format.
    #>
    [CmdletBinding()]
    param()

    process {
        # The CORRECT scope format discovered from CupOfOwls/kroger-api
        return "cart.basic:write profile.compact"
    }
}
