@{
    RootModule        = 'DotWebApi.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '8b3f4e7c-9a2d-4b6c-8e1f-5d7a3b2c1e9f'
    Author            = 'Derek Lomax'
    Description       = 'General web API integration framework for PowerShell with support for multiple services including Kroger and Spoonacular.'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'api', 'webapi', 'kroger', 'spoonacular', 'shopping')
        }
    }
    VariablesToExport = ''

    # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
    # must be explicitly set! Never use * because the module will not load if that item is called.

    CmdletsToExport   = @()
    AliasesToExport   = @(
        # Kroger aliases
        'kroger'
        'kfind'
        'kadd'
        'kcart'
    )
    FunctionsToExport = @(
        # Common functions
        'Invoke-WebApi'
        'Get-WebApiToken'
        'Test-WebApiTokenExpired'
        'Clear-WebApiTokenCache'
        'ConvertTo-KrogerProduct'
        'ConvertTo-KrogerCartItem'

        # Kroger functions
        'Connect-KrogerApi'
        'Connect-KrogerUser'
        'Connect-KrogerPkce'
        'Disconnect-KrogerUser'
        'Get-KrogerUserSession'
        'Update-KrogerUserToken'
        'Get-KrogerCartId'
        'Get-KrogerCorrectScopes'
        'Search-KrogerProduct'
        'Get-KrogerProductDetails'
        'Add-KrogerCartItem'
        'Get-KrogerCart'
        'Remove-KrogerCartItem'
        'Clear-KrogerCart'
        'Update-KrogerCartItem'

        # Spoonacular functions (existing)
        'Use-SpoonacularApi'
    )
}
