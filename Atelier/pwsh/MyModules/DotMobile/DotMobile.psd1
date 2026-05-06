@{
    RootModule        = 'DotMobile.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a7b8c9d0-e1f2-4a5b-8c9d-0e1f2a3b4c5d'
    Author            = 'Derek Lomax'
    Description       = 'Cross-platform mobile development automation functions for Android, Flutter, and iOS'
    PrivateData       = @{
        PSData = @{
            Tags = @('mobile', 'android', 'flutter', 'ios')
        }
    }
    VariablesToExport = ''
    CmdletsToExport   = @()
    AliasesToExport   = @()
    # For maximum lazy load module performance list every function here.
    # Do not use '*', mainly because it pwsh will not autoload the module for unlisted functions.
    FunctionsToExport = @(
        # Android functions
        'Get-AdbDevices'
        'New-AdbScreenshot'
        'Get-AdbImages'
        'Update-AndroidApplications'
        'Get-AdbLogCode'
        # Flutter functions
        'Get-FlutterGlobalOptions'
        'Get-FlutterCommandsAndNonGlobalOptions'
        'Invoke-FlutterBuild'
    )
}
