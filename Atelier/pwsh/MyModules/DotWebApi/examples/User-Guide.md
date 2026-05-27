# Kroger API User Authentication Guide

## Overview

The DotWebApi module supports two authentication modes:

1. **API Credentials Mode** - Product search and general API access
2. **User Authentication Mode** - Personal cart access and user-specific features

## Setting Up Credentials

### 1. API Credentials (Required for Both Modes)
```powershell
# Set your Kroger API credentials (one-time setup)
Set-Secret -Name 'KrogerApiKey' -Secret 'your-api-token'
Set-Secret -Name 'KrogerClientId' -Secret 'your-client-id'
```

### 2. User Authentication (Optional - For Personal Cart Access)
User authentication allows you to access your personal Kroger shopping cart.

## Authentication Methods

### Method 1: Direct Login (Simplest - No Website Needed!) ⭐
```powershell
# Sign in directly with your Kroger credentials
Connect-KrogerUser -Username 'your@email.com' -Password 'your_password'

# That's it! You're now authenticated and can access your personal cart
```

### Method 2: Manual Token Entry
```powershell
# If you already have OAuth2 tokens
Connect-KrogerUser -AccessToken 'your_access_token' -RefreshToken 'your_refresh_token'
```

### Method 3: Product Search Only (No Login Required)
```powershell
# For product search, you don't need to sign in:
Search-KrogerProduct -SearchTerm 'milk'
```

## Using Your Personal Cart

Once authenticated, you can access your personal shopping cart:

```powershell
# View your cart contents
Get-KrogerCart

# Search and add items to your cart
Search-KrogerProduct -SearchTerm 'milk' |
    Where-Object { $_.Brand -eq 'Kroger' -and $_.InStock } |
    Select-Object -First 1 |
    Add-KrogerCartItem -Quantity 2

# View cart again to see added items
Get-KrogerCart

# Update item quantities
Get-KrogerCart | Update-KrogerCartItem -UpdateQuantity 3

# Remove items
Get-KrogerCart | Remove-KrogerCartItem

# Clear entire cart
Clear-KrogerCart -WhatIf  # Use -WhatIf to preview first
```

## Session Management

```powershell
# Check current session
Get-KrogerUserSession

# Sign out
Disconnect-KrogerUser

# Sign in again (will reuse existing session if valid)
Connect-KrogerUser -UseDeviceFlow
```

## Anonymous vs User Cart

### Anonymous Cart (No Sign-In Required)
```powershell
# This works without user authentication
Search-KrogerProduct -SearchTerm 'eggs' |
    Add-KrogerCartItem -Quantity 1
```

### User Cart (Requires Sign-In)
```powershell
# Sign in first
Connect-KrogerUser -UseDeviceFlow

# Now your items go to your personal Kroger account
Search-KrogerProduct -SearchTerm 'milk' |
    Add-KrogerCartItem -Quantity 2

# View your personal cart
Get-KrogerCart
```

## Workflow Examples

### Complete Shopping Workflow
```powershell
# 1. Sign in to your Kroger account
Connect-KrogerUser -UseDeviceFlow

# 2. Search for products
$milk = Search-KrogerProduct -SearchTerm 'milk' |
    Where-Object { $_.InStock } |
    Select-Object -First 1

# 3. Add to your cart
$milk | Add-KrogerCartItem -Quantity 2

# 4. Check your cart
Get-KrogerCart

# 5. Sign out when done
Disconnect-KrogerUser
```

### Shopping List Workflow
```powershell
# Sign in
Connect-KrogerUser -UseDeviceFlow

# Process a shopping list
$shoppingList = @(
    'milk',
    'eggs',
    'bread',
    'butter'
)

foreach ($item in $shoppingList) {
    Search-KrogerProduct -SearchTerm $item |
        Where-Object { $_.InStock } |
        Select-Object -First 1 |
        Add-KrogerCartItem
}

# Review your cart
Get-KrogerCart

# Sign out
Disconnect-KrogerUser
```

## Troubleshooting

### Session Expired
```powershell
# If you get authentication errors, sign in again
Connect-KrogerUser -UseDeviceFlow -ForceReauth
```

### Check Authentication Status
```powershell
# See if you're signed in
Get-KrogerUserSession

# See what functions are available
Get-Command -Module DotWebApi | Where-Object { $_.Name -like '*Kroger*' }
```

### Clear All Sessions
```powershell
# Sign out and clear all cached tokens
Disconnect-KrogerUser
Clear-WebApiTokenCache
```

## Security Notes

- **Secrets are stored securely** using PowerShell SecretManagement
- **User sessions are stored locally** in `~/.cache/dotwebapi/` (Linux/Mac) or `%LOCALAPPDATA%\DotWebApi\` (Windows)
- **Tokens expire automatically** after the configured timeout
- **No credentials are hardcoded** in any scripts

## API vs User Access

| Feature | API Credentials | User Authentication |
|---------|----------------|-------------------|
| Product Search | ✅ | ✅ |
| Anonymous Cart | ✅ | ❌ |
| Personal Cart | ❌ | ✅ |
| Order History | ❌ | ✅ |
| Saved Lists | ❌ | ✅ |
| Profile Management | ❌ | ✅ |

## Getting Help

```powershell
# Get help for specific commands
Get-Help Connect-KrogerUser -Detailed
Get-Help Get-KrogerCart -Examples
Get-Help Add-KrogerCartItem -Full
```