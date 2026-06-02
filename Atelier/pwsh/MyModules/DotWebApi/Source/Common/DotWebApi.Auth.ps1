# Script-level token cache for OAuth2 tokens
$Script:WebApiTokenCache = @{}

function Get-WebApiToken
{
    <#
    .SYNOPSIS
    Retrieves or refreshes OAuth2 tokens for web API integrations.

    .DESCRIPTION
    Manages OAuth2 tokens for various web API services. Implements token caching,
    automatic refresh, and secure credential retrieval using Microsoft.PowerShell.SecretManagement.

    .PARAMETER ServiceName
    The name of the service (e.g., 'Kroger', 'Spoonacular').

    .PARAMETER TokenEndpoint
    The OAuth2 token endpoint URL.

    .PARAMETER Scope
    OAuth2 scope(s) to request.

    .PARAMETER ForceRefresh
    Force token refresh even if cached token is valid.

    .PARAMETER ClientId
    OAuth2 client ID. Defaults to retrieving from secret store.

    .PARAMETER ClientSecret
    OAuth2 client secret. Defaults to retrieving from secret store.

    .EXAMPLE
    Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope 'product.compact'

    .EXAMPLE
    Get-WebApiToken -ServiceName 'Kroger' -TokenEndpoint 'https://api.kroger.com/v1/connect/oauth2/token' -Scope 'product.compact' -ClientId 'test_id' -ClientSecret 'test_secret'

    .OUTPUTS
    PSObject with token information including access_token, expires_in, etc.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [string]$TokenEndpoint,

        [Parameter(Mandatory)]
        [string[]]$Scope,

        [Parameter()]
        [switch]$ForceRefresh,

        [Parameter()]
        [string]$ClientId = (Get-Secret -Name "${ServiceName}ClientId" -AsPlainText -ErrorAction SilentlyContinue),

        [Parameter()]
        [string]$ClientSecret = (Get-Secret -Name "${ServiceName}ApiKey" -AsPlainText -ErrorAction SilentlyContinue)
    )

    # Check cache first
    if (-not $ForceRefresh -and $Script:WebApiTokenCache.ContainsKey($ServiceName))
    {
        $cachedToken = $Script:WebApiTokenCache[$ServiceName]
        if (-not (Test-WebApiTokenExpired -Token $cachedToken))
        {
            Write-Verbose "Using cached token for $ServiceName"
            return $cachedToken
        }
    }

    Write-Verbose "Fetching new token for $ServiceName"

    # Validate we have credentials
    if (-not $ClientId -or -not $ClientSecret)
    {
        throw "Failed to retrieve credentials for $ServiceName. Please store secrets using: Set-Secret -Name '${ServiceName}ClientId' -Secret 'your-client-id' and Set-Secret -Name '${ServiceName}ApiKey' -Secret 'your-api-key'"
    }

    # Build OAuth2 token request
    $tokenParams = @{
        grant_type    = 'client_credentials'
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = $Scope -join ' '
    }

    try
    {
        # Request new token
        $response = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Body $tokenParams -ErrorAction Stop

        # Add expiration timestamp
        $response | Add-Member -NotePropertyName 'expires_at' -NotePropertyValue (Get-Date).AddSeconds($response.expires_in) -Force

        # Cache the token
        $Script:WebApiTokenCache[$ServiceName] = $response

        Write-Verbose "Successfully obtained and cached token for $ServiceName"
        return $response
    } catch
    {
        throw "Failed to obtain OAuth2 token for $ServiceName`: $($_.Exception.Message)"
    }
}

function Test-WebApiTokenExpired
{
    <#
    .SYNOPSIS
    Tests if an OAuth2 token is expired or will expire soon.

    .DESCRIPTION
    Checks if a token is expired or will expire within a buffer time (default 5 minutes).

    .PARAMETER Token
    The token object to test.

    .PARAMETER BufferMinutes
    Minutes before expiration to consider token as expired (default: 5).

    .EXAMPLE
    Test-WebApiTokenExpired -Token $tokenObject

    .OUTPUTS
    Boolean indicating if token is expired.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [object]$Token,

        [Parameter()]
        [ValidateRange(0, 60)]
        [int]$BufferMinutes = 5
    )

    if (-not $Token -or -not $Token.expires_at)
    {
        return $true
    }

    $expirationTime = $Token.expires_at
    $bufferTime = (Get-Date).AddMinutes($BufferMinutes)

    return $expirationTime -lt $bufferTime
}

function Clear-WebApiTokenCache
{
    <#
    .SYNOPSIS
    Clears cached OAuth2 tokens.

    .DESCRIPTION
    Removes all cached tokens or tokens for a specific service.

    .PARAMETER ServiceName
    Optional service name to clear only that service's tokens.

    .EXAMPLE
    Clear-WebApiTokenCache

    .EXAMPLE
    Clear-WebApiTokenCache -ServiceName 'Kroger'
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ServiceName
    )

    if ($ServiceName)
    {
        if ($Script:WebApiTokenCache.ContainsKey($ServiceName))
        {
            $Script:WebApiTokenCache.Remove($ServiceName)
            Write-Verbose "Cleared token cache for $ServiceName"
        }
    } else
    {
        $Script:WebApiTokenCache.Clear()
        Write-Verbose "Cleared all token caches"
    }
}
