@{
    RootModule        = 'DotAndroid.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '48382495-3092-44a6-b6c4-e3731d59e802'
    Author            = 'Derek Lomax'
    Description       = 'Android adb automation functions'
    PowerShellVersion = '7.4'
    PrivateData       = @{
        PSData = @{
            Tags = @('dots')
        }
    }
    VariablesToExport = ''
    CmdletsToExport   = @()
    AliasesToExport   = @()
    # For maximum lazy load module performance list every function here.
    # Do not use '*', mainly because it pwsh will not autoload the module for unlisted functions.
    FunctionsToExport = @(
        'Get-AdbDevices'
        'Get-AdbImages'
        'New-AdbScreenshot'
        'Update-AndroidApplications'
        'Get-AdbLogCode'
    )
}

