@{
    RootModule        = 'DotWebApi.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '8b3f4e7c-9a2d-4b6c-8e1f-5d7a3b2c1e9f'
    Author            = 'Derek Lomax'
    Description       = 'General web API integration framework for PowerShell with support for multiple services including Kroger, Spoonacular and Kokoro TTS, plus a generator that builds PowerShell clients from OpenAPI/Swagger documents.'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots', 'api', 'webapi', 'kroger', 'spoonacular', 'shopping', 'openapi', 'swagger', 'kokoro', 'tts')
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

        # OpenAPI generation aliases
        'openapigen'
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
        'Find-KrogerStore'
        'Set-KrogerDefaultLocation'
        'Get-KrogerDefaultLocation'
        'Clear-KrogerDefaultLocation'
        'Test-KrogerProductStock'

        # Spoonacular functions (existing)
        'Use-SpoonacularApi'

        # OpenAPI client generation
        'New-OpenApiClient'
        'Update-ModuleManifestExport'
        # BEGIN generated: Kokoro
        'Clear-KokoroDefaultEndpoint'
        'ConvertTo-KokoroPhoneme'
        'ConvertTo-KokoroSsmlText'
        'Get-KokoroDefaultEndpoint'
        'Get-KokoroModel'
        'Get-KokoroModelById'
        'Get-KokoroModelStatus'
        'Get-KokoroSsmlCapability'
        'Get-KokoroStorageInfo'
        'Get-KokoroSystemInfo'
        'Get-KokoroThreadInfo'
        'Get-KokoroVoice'
        'Get-KokoroWebConfig'
        'Get-KokoroWebFile'
        'Join-KokoroVoice'
        'New-KokoroCaptionedSpeech'
        'New-KokoroDialogue'
        'New-KokoroDialogueTurn'
        'New-KokoroNormalizationOption'
        'New-KokoroSpeech'
        'New-KokoroSpeechFromPhoneme'
        'New-KokoroVoiceAlias'
        'Optimize-KokoroSpeech'
        'Save-KokoroAudioFile'
        'Set-KokoroCredential'
        'Set-KokoroDefaultEndpoint'
        'Test-KokoroEndpoint'
        'Test-KokoroHealth'
        'Unregister-KokoroModel'
        'Update-KokoroModel'
        # END generated: Kokoro
    )
    FormatsToProcess  = @(
        'DotWebApi.format.ps1xml'
    )
}
